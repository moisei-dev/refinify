# Download and install AutoHotkey v2
$ahkUrl = "https://www.autohotkey.com/download/ahk-v2.exe"
$tempPath = "$env:TEMP\AutoHotkey_v2_setup.exe"

try {
    Write-Host "Downloading AutoHotkey v2..."
    Invoke-WebRequest -Uri $ahkUrl -OutFile $tempPath
    
    Write-Host "Installing AutoHotkey v2..."
    Start-Process -FilePath $tempPath -ArgumentList "/S" -Wait
    
    Write-Host "AutoHotkey v2 installed successfully"
    Remove-Item $tempPath -Force
    exit 0
} catch {
    Write-Error "Failed to install AutoHotkey v2: $_"
    exit 1
}