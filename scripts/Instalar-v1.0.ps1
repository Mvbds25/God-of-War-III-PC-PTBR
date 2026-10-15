param(
    [Parameter(Mandatory=$true)]
    [string]$GameDir,

    [string]$PackageDir
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($PackageDir)) {
    $PackageDir = Split-Path -Parent $PSScriptRoot
}
$GameDir = (Resolve-Path -LiteralPath $GameDir).Path
$ManifestPath = Join-Path $PackageDir "manifest.csv"
$PatchesRoot = Join-Path $PackageDir "patches"
$Xdelta = Join-Path $PackageDir "tools\xdelta3.exe"
$PortugueseRoot = Join-Path $GameDir "PORTUGUESE\SOUNDS\STREAMS_PS4"
$AudioRoot = $GameDir
$BackupRoot = Join-Path $GameDir "_PTBR_BACKUP_v1"
$TempRoot = Join-Path $env:TEMP ("GOW3_PTBR_" + [guid]::NewGuid().ToString("N"))

foreach($p in @($ManifestPath,$PatchesRoot,$Xdelta,$PortugueseRoot)) {
    if(!(Test-Path -LiteralPath $p)) { throw "Necessario e nao encontrado: $p" }
}

$Manifest = @(Import-Csv -LiteralPath $ManifestPath)
if($Manifest.Count -ne 1159) { throw "Manifesto invalido: esperado 1159, encontrado $($Manifest.Count)." }

New-Item -ItemType Directory -Force -Path $BackupRoot,$TempRoot | Out-Null

# Index all XVAGs in the game by filename. SHA is calculated lazily only for candidates
# with the expected name, keeping startup reasonably fast.
$ByName = @{}
Get-ChildItem -LiteralPath $AudioRoot -Recurse -File -Filter "*.XVAG" -ErrorAction SilentlyContinue |
ForEach-Object {
    $k=$_.Name.ToUpperInvariant()
    if(!$ByName.ContainsKey($k)){ $ByName[$k]=New-Object System.Collections.Generic.List[object] }
    $ByName[$k].Add($_)
}

function Find-Base([string]$Name,[string]$ExpectedHash) {
    $k=$Name.ToUpperInvariant()
    if(!$ByName.ContainsKey($k)){ return $null }
    foreach($f in $ByName[$k]) {
        $h=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        if($h -eq $ExpectedHash){ return $f.FullName }
    }
    return $null
}

$Prepared = New-Object System.Collections.Generic.List[object]
$i=0
Write-Host "`n=== GOD OF WAR III PC - DUBLAGEM PT-BR v1.0 ===" -ForegroundColor Cyan
Write-Host "Pre-validando e reconstruindo 1159 arquivos antes de alterar o jogo...`n"

try {
    foreach($m in $Manifest) {
        $i++
        $base = Find-Base $m.BaseArquivo $m.BaseSHA256
        if(!$base) {
            throw "Base compativel nao encontrada para '$($m.Destino)'. Esperado $($m.BaseArquivo) SHA256 $($m.BaseSHA256)"
        }

        $patch = Join-Path $PackageDir $m.Patch
        if(!(Test-Path -LiteralPath $patch)){ throw "Patch ausente: $($m.Patch)" }
        if((Get-FileHash $patch -Algorithm SHA256).Hash -ne $m.PatchSHA256) {
            throw "Patch corrompido: $($m.Patch)"
        }

        $temp = Join-Path $TempRoot $m.Destino
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $temp) | Out-Null

        & $Xdelta -f -d -s $base $patch $temp
        if($LASTEXITCODE -ne 0 -or !(Test-Path $temp)){ throw "Falha xdelta: $($m.Destino)" }

        $fh=(Get-FileHash $temp -Algorithm SHA256).Hash
        if($fh -ne $m.FinalSHA256){ throw "Reconstrucao invalida: $($m.Destino)" }

        $Prepared.Add([PSCustomObject]@{ Manifest=$m; Temp=$temp; Base=$base })

        if(($i % 100)-eq 0 -or $i -eq 1159){ Write-Host "[$i/1159] pre-validado" -ForegroundColor Green }
    }

    Write-Host "`nTodos os 1159 arquivos foram reconstruidos corretamente." -ForegroundColor Green
    Write-Host "Iniciando backup e instalacao...`n"

    $Installed=0
    foreach($p in $Prepared) {
        $m=$p.Manifest
        $dst=Join-Path $PortugueseRoot $m.Destino
        $bak=Join-Path $BackupRoot $m.Destino

        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        if(Test-Path -LiteralPath $dst) {
            if(!(Test-Path -LiteralPath $bak)) {
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bak) | Out-Null
                Copy-Item -LiteralPath $dst -Destination $bak
                $bh1=(Get-FileHash $dst -Algorithm SHA256).Hash
                $bh2=(Get-FileHash $bak -Algorithm SHA256).Hash
                if($bh1 -ne $bh2){ throw "Falha no backup: $($m.Destino)" }
            }
        }

        Copy-Item -LiteralPath $p.Temp -Destination $dst -Force
        if((Get-FileHash $dst -Algorithm SHA256).Hash -ne $m.FinalSHA256) {
            throw "Falha na verificacao apos instalar: $($m.Destino)"
        }
        $Installed++
    }

    @"
God of War III PC - PT-BR v1.0
Instalado: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Arquivos: $Installed
Manifesto: manifest.csv
"@ | Set-Content -LiteralPath (Join-Path $BackupRoot "_INSTALACAO.txt") -Encoding UTF8

    Write-Host "`n=== INSTALACAO CONCLUIDA ===" -ForegroundColor Green
    Write-Host "Arquivos instalados: $Installed/1159"
    Write-Host "Backup: $BackupRoot"
}
finally {
    if(Test-Path -LiteralPath $TempRoot){ Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

