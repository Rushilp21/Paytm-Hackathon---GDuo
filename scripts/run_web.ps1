$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency installation failed.' }
    flutter run -d chrome --web-port 5173
} finally { Pop-Location }
