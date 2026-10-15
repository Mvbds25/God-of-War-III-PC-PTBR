$ErrorActionPreference="Stop"

$Project="C:\Games\God-of-War-III-PC-PTBR"
$Release=Join-Path $Project "release-v1.0"
$Dist=Join-Path $Project "dist"
$XdeltaSource=Join-Path $Project "xdelta3-3.2.2-windows-x86_64\xdelta3.exe"
$Installer=Join-Path $Project "scripts\Instalar-v1.0.ps1"
$Restore=Join-Path $Project "scripts\Restaurar-v1.0.ps1"

foreach($p in @($Release,$XdeltaSource,$Installer,$Restore,(Join-Path $Release "manifest.csv"),(Join-Path $Release "patches"))){
    if(!(Test-Path $p)){throw "Ausente: $p"}
}

$patchCount=@(Get-ChildItem (Join-Path $Release "patches") -Recurse -File -Filter "*.xdelta").Count
if($patchCount -ne 1159){throw "Esperava 1159 patches; encontrei $patchCount"}

$Package=Join-Path $Dist "God-of-War-III-PC-PTBR-v1.0"
if(Test-Path $Package){Remove-Item $Package -Recurse -Force}
New-Item -ItemType Directory -Force -Path $Package,(Join-Path $Package "scripts"),(Join-Path $Package "tools") | Out-Null

Copy-Item (Join-Path $Release "manifest.csv") $Package
Copy-Item (Join-Path $Release "patches") $Package -Recurse
Copy-Item $Installer (Join-Path $Package "scripts\Instalar-PTBR.ps1")
Copy-Item $Restore (Join-Path $Package "scripts\Restaurar-Original.ps1")
Copy-Item $XdeltaSource (Join-Path $Package "tools\xdelta3.exe")

$readme=@"
God of War III PC - Dublagem PT-BR v1.0

Requer uma instalacao compativel do port nativo de PC.

Instalar:
powershell -ExecutionPolicy Bypass -File ".\scripts\Instalar-PTBR.ps1" -GameDir "CAMINHO\CUSA01623"

Restaurar:
powershell -ExecutionPolicy Bypass -File ".\scripts\Restaurar-Original.ps1" -GameDir "CAMINHO\CUSA01623"

O instalador verifica SHA-256 das bases, patches e arquivos reconstruidos.
"@
$readme | Set-Content (Join-Path $Package "LEIA-ME.txt") -Encoding UTF8

New-Item -ItemType Directory -Force -Path $Dist | Out-Null
$Zip=Join-Path $Dist "God-of-War-III-PC-PTBR-v1.0.zip"
if(Test-Path $Zip){Remove-Item $Zip -Force}
Compress-Archive -Path (Join-Path $Package "*") -DestinationPath $Zip -CompressionLevel Optimal

$hash=(Get-FileHash $Zip -Algorithm SHA256).Hash
$size=(Get-Item $Zip).Length
@"
Arquivo: $(Split-Path $Zip -Leaf)
Bytes: $size
SHA256: $hash
Patches: 1159
"@ | Set-Content (Join-Path $Dist "God-of-War-III-PC-PTBR-v1.0.sha256.txt") -Encoding UTF8

Write-Host "`n=== PACOTE v1.0 PRONTO ===" -ForegroundColor Green
Write-Host "ZIP: $Zip"
Write-Host ("Tamanho: {0:N2} MB" -f ($size/1MB))
Write-Host "SHA256: $hash"
