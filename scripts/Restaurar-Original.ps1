param(
    [Parameter(Mandatory=$true)]
    [string]$GameDir
)
$ErrorActionPreference="Stop"
$GameDir=$GameDir.Trim('"')
$Target=Join-Path $GameDir "PORTUGUESE\SOUNDS\STREAMS_PS4"
$Backup=Join-Path $GameDir "_PTBR_BACKUP"
if(!(Test-Path -LiteralPath $Backup)){ throw "Backup PT-BR nao encontrado: $Backup" }

$files=@(Get-ChildItem -LiteralPath $Backup -File -Recurse | Where-Object {$_.Name -ne "manifest.csv"})
if($files.Count -eq 0){ throw "Nenhum arquivo de backup encontrado." }

foreach($f in $files){
    $rel=$f.FullName.Substring($Backup.Length).TrimStart('\')
    $dst=Join-Path $Target $rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item -LiteralPath $f.FullName -Destination $dst -Force
    if((Get-FileHash $f.FullName -Algorithm SHA256).Hash -ne (Get-FileHash $dst -Algorithm SHA256).Hash){
        throw "Falha ao restaurar: $rel"
    }
}
Write-Host "RESTAURACAO CONCLUIDA: $($files.Count) arquivos." -ForegroundColor Green
