# Quick-CLI Universal One-Liner Installer
# This script clones or downloads Quick-CLI and sets it up.

Write-Host ">>> Quick-CLI One-Liner Installer <<<" -ForegroundColor Cyan

$installDir = Join-Path $HOME ".quick-cli"
$repoUrl = "https://github.com/Xiaode-AI/Quick-CLI"
$zipUrl = "$repoUrl/archive/refs/heads/main.zip"

# 1. Prepare directory
if (Test-Path $installDir) {
    Write-Host "Cleaning up old installation..." -ForegroundColor Gray
    Remove-Item $installDir -Recurse -Force
}
New-Item -ItemType Directory -Path $installDir | Out-Null

# 2. Download Content
Write-Host "Downloading Quick-CLI from GitHub..." -ForegroundColor Yellow
try {
    # If git is available, clone is better
    if (Get-Command git -ErrorAction SilentlyContinue) {
        git clone $repoUrl $installDir
    } else {
        # Fallback to Zip download
        $zipFile = Join-Path $HOME "quick-cli-temp.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
        Expand-Archive -Path $zipFile -DestinationPath $HOME -Force
        Move-Item (Join-Path $HOME "Quick-CLI-main") $installDir
        Remove-Item $zipFile
    }
} catch {
    Write-Host "Failed to download. Please check your network or URL." -ForegroundColor Red
    return
}

# 3. Trigger Local Setup
if (Test-Path (Join-Path $installDir "setup.ps1")) {
    Set-Location $installDir
    .\scripts\setup.ps1
}

Write-Host "`nSuccessfully installed to $installDir" -ForegroundColor Green
Write-Host "Restart your terminal and type 'qc' to start!" -ForegroundColor Cyan
