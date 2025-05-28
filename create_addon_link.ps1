# PowerShell script to create symbolic link for pfQuest addon
# Run as Administrator

$source = "C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master"
$target = "E:\3.3.5\interface\addons\pfQuest-wotlk"

Write-Host "Creating symbolic link for pfQuest addon..." -ForegroundColor Green
Write-Host "Source: $source" -ForegroundColor Cyan
Write-Host "Target: $target" -ForegroundColor Cyan

# Remove existing link if it exists
if (Test-Path $target) {
    Write-Host "Removing existing link..." -ForegroundColor Yellow
    Remove-Item $target -Force -Recurse
}

# Create symbolic link
try {
    New-Item -ItemType SymbolicLink -Path $target -Target $source -Force
    Write-Host "SUCCESS: Symbolic link created!" -ForegroundColor Green
    Write-Host "Game will see addon at: $target" -ForegroundColor Cyan
    Write-Host "But files are actually in: $source" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Failed to create symbolic link" -ForegroundColor Red
    Write-Host "Make sure you run PowerShell as Administrator" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Read-Host "Press Enter to continue"
