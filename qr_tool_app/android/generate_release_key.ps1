# PowerShell Script to regenerate or inspect release keystore for Ontero QR
$KeytoolPath = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
if (-not (Test-Path $KeytoolPath)) {
    $KeytoolPath = "keytool"
}

Write-Host "Checking upload keystore..." -ForegroundColor Cyan
& $KeytoolPath -list -v -keystore "app\upload-keystore.jks" -storepass "ontero@qr2026!"
