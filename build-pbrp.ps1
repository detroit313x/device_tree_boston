# PBRP Boston Recovery Build Launcher for Windows
# This script builds PBRP recovery for Motorola Boston in WSL2

param(
    [switch]$SkipDeps = $false,
    [string]$PBRPBranch = "android-14.0"
)

Write-Host "=========================================="
Write-Host "PBRP Boston Recovery Builder (WSL2)"
Write-Host "=========================================="
Write-Host ""

# Check if WSL2 is available
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wsl) {
    Write-Host "❌ WSL2 is not installed or not in PATH"
    Write-Host "Please install WSL2 first: https://docs.microsoft.com/en-us/windows/wsl/install"
    exit 1
}

# Get device tree path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildScript = Join-Path $scriptDir "build-pbrp.sh"

if (-not (Test-Path $buildScript)) {
    Write-Host "❌ build-pbrp.sh not found at: $buildScript"
    exit 1
}

# Convert Windows path to WSL path
$scriptDirWSL = (wsl bash -c "wslpath '$scriptDir'" | Out-String).Trim()
Write-Host "[1] Using device tree path in WSL: $scriptDirWSL"

Write-Host "[2] Starting WSL2 Ubuntu..."
Write-Host ""

# Run the build script in WSL
$buildArgs = @("--branch", $PBRPBranch)
if ($SkipDeps) {
    $buildArgs += "--skip-deps"
}
$argString = ($buildArgs | ForEach-Object { "'$_'" }) -join " "
wsl bash -c "cd '$scriptDirWSL' && bash build-pbrp.sh $argString"

$buildExitCode = $LASTEXITCODE

Write-Host ""
if ($buildExitCode -eq 0) {
    Write-Host "=========================================="
    Write-Host "✅ Build completed successfully!"
    Write-Host "=========================================="
    
    # Try to find and report the output
    $recoveryImg = (wsl bash -lc "printf '%s' \"\$HOME/pbrp-build/source/out/target/product/boston/vendor_boot.img\"" | Out-String).Trim()
    Write-Host "Vendor boot image (WSL path): $recoveryImg"
    Write-Host ""
    Write-Host "To flash to your device:"
    Write-Host "1. Connect device via USB with USB debugging enabled"
    Write-Host "2. Open PowerShell in the output directory"
    Write-Host "3. Run: fastboot flash vendor_boot vendor_boot.img"
    Write-Host "4. Run: fastboot reboot recovery"
} else {
    Write-Host "❌ Build failed with exit code: $buildExitCode"
    exit $buildExitCode
}
