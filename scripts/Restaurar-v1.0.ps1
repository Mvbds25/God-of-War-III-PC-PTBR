param(
    [Parameter(Mandatory=$true)]
    [string]$GameDir
)

$ErrorActionPreference = "Stop"

$GameDir = (Resolve-Path -LiteralPath $GameDir).Path
$Target = Join-Path $GameDir "PORTUGUESE\SOUNDS\STREAMS_PS4"
$Backup = Join-Path $GameDir "_PTBR_BACKUP_v1"
$CreatedList = Join-Path $Backup "_CRIADOS.txt"

if(!(Test-Path -LiteralPath $Backup)) {
    throw "Backup v1 nao encontrado: $Backup"
}

$files = @(
    Get-ChildItem -LiteralPath $Backup -Recurse -File |
    Where-Object {
        $_.Name -ne "_INSTALACAO.txt" -and
        $_.Name -ne "_CRIADOS.txt"
    }
)

$Restored = 0

foreach($f in $files) {
    $rel = $f.FullName.Substring($Backup.Length).TrimStart('\')
    $dst = Join-Path $Target $rel

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item -LiteralPath $f.FullName -Destination $dst -Force

    $h1 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    $h2 = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash

    if($h1 -ne $h2) {
        throw "Falha ao restaurar: $rel"
    }

    $Restored++
}

$Removed = 0

if(Test-Path -LiteralPath $CreatedList) {

    $Created = @(
        Get-Content -LiteralPath $CreatedList |
        Where-Object { ![string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique
    )

    foreach($rel in $Created) {

        # Protecao contra caminhos fora da pasta de destino
        if([IO.Path]::IsPathRooted($rel) -or $rel -match '(^|[\\/])\.\.([\\/]|$)') {
            throw "Entrada insegura em _CRIADOS.txt: $rel"
        }

        $dst = Join-Path $Target $rel

        if(Test-Path -LiteralPath $dst) {
            Remove-Item -LiteralPath $dst -Force
            $Removed++
        }
    }
}

Write-Host "`n=== RESTAURACAO CONCLUIDA ===" -ForegroundColor Green
Write-Host "Arquivos restaurados: $Restored"
Write-Host "Arquivos criados pelo PT-BR removidos: $Removed"
