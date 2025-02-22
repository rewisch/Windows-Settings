# Check if running as Administrator. If not, display an error and exit.
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be executed as an Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "Starting update process for FPilot.exe..." -ForegroundColor Cyan

# Define paths and URL
$targetDir   = "C:\Program Files\FilePilot"
$exeName     = "FPilot.exe"
$exePath     = Join-Path $targetDir $exeName
$archiveDir  = Join-Path $targetDir "archive"
$tempFile    = Join-Path $env:TEMP "FPilot_download.exe"
$downloadUrl = "https://filepilot.tech/download/latest"

Write-Host "Using target directory: $targetDir" -ForegroundColor Yellow

# Ensure the target directory exists
if (!(Test-Path -Path $targetDir)) {
    Write-Host "Target directory does not exist. Creating $targetDir..." -ForegroundColor Yellow
    New-Item -Path $targetDir -ItemType Directory | Out-Null
} else {
    Write-Host "Target directory exists." -ForegroundColor Green
}

# Ensure the archive directory exists
if (!(Test-Path -Path $archiveDir)) {
    Write-Host "Archive directory does not exist. Creating $archiveDir..." -ForegroundColor Yellow
    New-Item -Path $archiveDir -ItemType Directory | Out-Null
} else {
    Write-Host "Archive directory exists." -ForegroundColor Green
}

# Attempt to download the new exe to a temporary file
Write-Host "Downloading new FPilot.exe from $downloadUrl..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -ErrorAction Stop
    # Verify the download by checking that the file exists and is not empty
    if (!(Test-Path $tempFile) -or ((Get-Item $tempFile).Length -eq 0)) {
        throw "Downloaded file is empty."
    }
    Write-Host "Download completed successfully. Temporary file located at: $tempFile" -ForegroundColor Green
}
catch {
    Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# If FPilot.exe exists, archive the current version with a timestamp
if (Test-Path -Path $exePath) {
    Write-Host "Current FPilot.exe found. Archiving current version..." -ForegroundColor Cyan
    $timestamp   = Get-Date -Format "yyyyMMddHHmmss"
    $archivedExe = Join-Path $archiveDir ("FPilot_" + $timestamp + ".exe")
    try {
        Copy-Item -Path $exePath -Destination $archivedExe -ErrorAction Stop
        Write-Host "Current version archived as: $archivedExe" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to archive current FPilot.exe: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "No existing FPilot.exe found. Skipping archiving." -ForegroundColor Yellow
}

# Check and maintain a maximum of 3 archive files.
$archiveFiles = Get-ChildItem -Path $archiveDir -Filter '*.exe' | Sort-Object LastWriteTime
while ($archiveFiles.Count -gt 3) {
    $oldestFile = $archiveFiles[0]
    Remove-Item -Path $oldestFile.FullName -Force
    Write-Host "Deleted oldest archive file: $($oldestFile.Name)" -ForegroundColor Yellow
    $archiveFiles = Get-ChildItem -Path $archiveDir -Filter '*.exe' | Sort-Object LastWriteTime
}

# Replace (or install) the current exe with the downloaded file
Write-Host "Updating FPilot.exe with the new version..." -ForegroundColor Cyan
try {
    Copy-Item -Path $tempFile -Destination $exePath -Force -ErrorAction Stop
    Write-Host "FPilot.exe updated successfully at: $exePath" -ForegroundColor Green
}
catch {
    Write-Host "Failed to update FPilot.exe: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Clean up the temporary file
Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
Remove-Item -Path $tempFile -Force

Write-Host "Update process completed." -ForegroundColor Cyan
