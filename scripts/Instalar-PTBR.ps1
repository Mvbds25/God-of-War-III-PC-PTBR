param(
    [string]$GameDir
)
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PatchRoot = Join-Path $ProjectRoot "patch"
$PatchStreams = Join-Path $PatchRoot "PORTUGUESE\SOUNDS\STREAMS_PS4"

if (-not $GameDir) {
    $GameDir = Read-Host "Informe a pasta CUSA01623 do jogo"
}
$GameDir = $GameDir.Trim('"')
if (!(Test-Path -LiteralPath $GameDir -PathType Container)) {
    throw "Pasta do jogo nao encontrada: $GameDir"
}
$TargetStreams = Join-Path $GameDir "PORTUGUESE\SOUNDS\STREAMS_PS4"
if (!(Test-Path -LiteralPath $TargetStreams -PathType Container)) {
    throw "Estrutura STREAMS_PS4 nao encontrada. Esta instalacao pode nao ser compativel: $TargetStreams"
}
if (!(Test-Path -LiteralPath $PatchStreams -PathType Container)) {
    throw "Pasta do patch nao encontrada: $PatchStreams"
}
$Files = @(Get-ChildItem -LiteralPath $PatchStreams -File -Recurse)
if ($Files.Count -eq 0) {
    throw "O pacote nao contem arquivos de audio. Adicione o patch distribuivel antes de instalar."
}

$BackupRoot = Join-Path $GameDir "_PTBR_BACKUP"
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
$Manifest = Join-Path $BackupRoot "manifest.csv"
$records = @()

Write-Host "`nGod of War III - Instalador PT-BR" -ForegroundColor Cyan
Write-Host "Arquivos no patch: $($Files.Count)"
Write-Host "Destino: $TargetStreams`n"

foreach ($f in $Files) {
    $rel = $f.FullName.Substring($PatchStreams.Length).TrimStart('\')
    $dst = Join-Path $TargetStreams $rel
    $bak = Join-Path $BackupRoot $rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null

    if (Test-Path -LiteralPath $dst) {
        if (!(Test-Path -LiteralPath $bak)) {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bak) | Out-Null
            Copy-Item -LiteralPath $dst -Destination $bak
        }
        $oldHash=(Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
    } else { $oldHash="" }

    Copy-Item -LiteralPath $f.FullName -Destination $dst -Force
    $srcHash=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    $dstHash=(Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
    if ($srcHash -ne $dstHash) { throw "Falha na verificacao SHA256: $rel" }

    $records += [PSCustomObject]@{
        Arquivo=$rel
        SHA256_Anterior=$oldHash
        SHA256_PTBR=$dstHash
    }
}
$records | Export-Csv -LiteralPath $Manifest -NoTypeInformation -Encoding UTF8
Write-Host "`nINSTALACAO CONCLUIDA: $($Files.Count) arquivos." -ForegroundColor Green
Write-Host "Backup: $BackupRoot"
