<#
.SYNOPSIS
    register-autopilot.ps1 - Upload this PC's Autopilot hardware hash to Intune.
.DESCRIPTION
    Path A (existing PC not yet in Autopilot). Wraps Microsoft's documented
    Get-WindowsAutopilotInfo procedure. Run from an elevated PowerShell on
    the PC itself, or in OOBE (Shift+F10 -> powershell).
    After upload: add the device to the correct Entra groups, wait for the
    Autopilot profile to show "Assigned", then reset the PC.
    Docs: docs/win-autopilot-reimage.md
.NOTES
    Tier:    Modifies settings (registers device in the tenant)
    Tested:  Windows 10/11, PowerShell 5.1
    Rights:  Intune Administrator (or delegated equivalent) at the sign-in prompt.
             Activate your PIM role BEFORE running.
.PARAMETER GroupTag
    Optional Autopilot group tag (only if your tenant uses tag-based dynamic groups).
.PARAMETER AddToGroup
    Optional Entra group display name to add the device to (requires group rights).
.PARAMETER Assign
    Wait until Intune assigns an Autopilot profile before exiting.
.PARAMETER Offline
    Save the hash to C:\HWID\AutopilotHWID.csv instead of uploading
    (import it later: Intune > Devices > Enrollment > Windows Autopilot > Devices > Import).
.PARAMETER Reset
    After upload, open the Windows "Reset this PC" wizard. Do NOT use until the
    profile shows Assigned (use -Assign, or check the Autopilot devices pane).
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\register-autopilot.ps1 -Assign
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\register-autopilot.ps1 -Offline
#>
[CmdletBinding()]
param(
    [string]$GroupTag,
    [string]$AddToGroup,
    [switch]$Assign,
    [switch]$Offline,
    [switch]$Reset
)

$ErrorActionPreference = 'Stop'

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error 'Run from an elevated PowerShell session.'
    exit 1
}

$serial = (Get-CimInstance Win32_BIOS).SerialNumber
Write-Host "Serial / service tag: $serial" -ForegroundColor Cyan

# Microsoft's documented prerequisites
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
$env:Path += ';C:\Program Files\WindowsPowerShell\Scripts'

if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Host '-> Installing NuGet provider'
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
}

Write-Host '-> Installing/updating Get-WindowsAutopilotInfo (can take several minutes)'
Install-Script -Name Get-WindowsAutopilotInfo -Force

if ($Offline) {
    New-Item -ItemType Directory -Path 'C:\HWID' -Force | Out-Null
    $out = 'C:\HWID\AutopilotHWID.csv'
    $apParams = @{ OutputFile = $out }
    if ($GroupTag) { $apParams.GroupTag = $GroupTag }
    Get-WindowsAutopilotInfo @apParams
    Write-Host "Saved: $out  (copy to USB, then import in Intune)" -ForegroundColor Green
    exit 0
}

Write-Host '-> Uploading hash. Sign in with your admin account when prompted.'
$apParams = @{ Online = $true }
if ($GroupTag)   { $apParams.GroupTag   = $GroupTag }
if ($AddToGroup) { $apParams.AddToGroup = $AddToGroup }
if ($Assign)     { $apParams.Assign     = $true }
Get-WindowsAutopilotInfo @apParams

Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Green
Write-Host "  1. Entra admin center: add device '$serial' to the Autopilot + building/area groups."
Write-Host '  2. Intune > Devices > Enrollment > Windows Autopilot > Devices: wait for Profile status = Assigned.'
Write-Host '     (Minutes for the hash; group-driven profile assignment can take several hours.)'
Write-Host '  3. Reset the PC (Settings > System > Recovery > Reset this PC > Remove everything),'
Write-Host '     or run an Intune Wipe from the admin center.'

if ($Reset) {
    $r = Read-Host 'Profile status confirmed Assigned? Open Reset this PC now? [y/N]'
    if ($r -match '^[yY]') { Start-Process systemreset.exe -ArgumentList '-factoryreset' }
}
