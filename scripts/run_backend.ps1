$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..\backend')
try {
    if (-not (Test-Path -LiteralPath '.env')) { Copy-Item -LiteralPath '.env.example' -Destination '.env' }
    dart run bin/server.dart
} finally { Pop-Location }
