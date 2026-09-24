param(
    [Parameter(Mandatory = $true)][string]$DeviceId,
    [switch]$Emulator
)
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Could not install Flutter dependencies.' }
    $apiEndpoint = 'http://10.0.2.2:8080'
    if (-not $Emulator) {
        $adbCommand = Get-Command adb -ErrorAction SilentlyContinue
        $adbExecutable = if ($adbCommand) { $adbCommand.Source } else { Join-Path $env:LOCALAPPDATA 'Android\sdk\platform-tools\adb.exe' }
        if (-not (Test-Path -LiteralPath $adbExecutable)) { throw 'adb not found. Add your Android SDK platform-tools directory to PATH.' }
        & $adbExecutable -s $DeviceId reverse tcp:8080 tcp:8080
        if ($LASTEXITCODE -ne 0) { throw 'USB forwarding failed. Unlock your phone and allow USB debugging.' }
        $apiEndpoint = 'http://127.0.0.1:8080'
    }
    flutter run -d $DeviceId --dart-define="API_BASE_URL=$apiEndpoint"
} finally { Pop-Location }
