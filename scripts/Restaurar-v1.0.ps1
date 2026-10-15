param(
    [Parameter(Mandatory=$true)]
    [string]$GameDir
)
$ErrorActionPreference="Stop"
$GameDir=(Resolve-Path -LiteralPath $GameDir).Path
$Target=Join-Path $GameDir "PORTUGUESE\SOUNDS\STREAMS_PS4"
$Backup=Join-Path $GameDir "_PTBR_BACKUP_v1"
if(!(Test-Path $Backup)){ throw "Backup v1 nao encontrado: $Backup" }

$files=@(Get-ChildItem $Backup -Recurse -File | Where-Object {$_.Name -ne "_INSTALACAO.txt"})
if($files.Count -eq 0){ throw "Backup vazio." }

$i=0
foreach($f in $files){
    $rel=$f.FullName.Substring($Backup.Length).TrimStart('\')
    $dst=Join-Path $Target $rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item $f.FullName $dst -Force
    if((Get-FileHash $f.FullName -Algorithm SHA256).Hash -ne (Get-FileHash $dst -Algorithm SHA256).Hash){
        throw "Falha ao restaurar $rel"
    }
    $i++
}
Write-Host "Restauracao concluida: $i arquivos." -ForegroundColor Green
