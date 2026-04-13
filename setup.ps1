# Quick-CLI Setup Assistant
# Sets up aliases and checks dependencies.

Write-Host "--- Quick-CLI Setup Assistant ---" -ForegroundColor Cyan

# 1. Check Dependencies
$dependencies = @("claude", "codex")
foreach ($dep in $dependencies) {
    if (Get-Command $dep -ErrorAction SilentlyContinue) {
        Write-Host "[OK] $dep is installed." -ForegroundColor Green
    } else {
        Write-Host "[!!] $dep is NOT found. Please install it via npm." -ForegroundColor Yellow
    }
}

# 2. Add to PATH (Permanent)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$PSScriptRoot*") {
    $newPath = "$currentPath;$PSScriptRoot"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "[DONE] Added location to your User PATH." -ForegroundColor Green
} else {
    Write-Host "[OK] Location is already in your PATH." -ForegroundColor Gray
}

# 3. Add Alias to Profile
$scriptPath = Join-Path $PSScriptRoot "Script.ps1"
$aliasCmd = "`nfunction qc { & '$scriptPath' }`nfunction quick { & '$scriptPath' }`nfunction quick-cli { & '$scriptPath' }"

if (Test-Path $PROFILE) {
    if ((Get-Content $PROFILE) -contains "function qc") {
        Write-Host "[OK] Alias 'qc/quick' already exists in your profile." -ForegroundColor Gray
    } else {
        Add-Content $PROFILE $aliasCmd
        Write-Host "[DONE] Shortcuts added to your PowerShell profile." -ForegroundColor Green
    }
} else {
    New-Item -Path $PROFILE -Type File -Force | Out-Null
    Set-Content $PROFILE $aliasCmd
    Write-Host "[DONE] Created profile and added shortcuts." -ForegroundColor Green
}

Write-Host "`nSetup complete! Please RESTART your Terminal." -ForegroundColor Cyan
Write-Host "You can now use: 'qc', 'quick', or 'quick-cli' from anywhere!" -ForegroundColor Green
