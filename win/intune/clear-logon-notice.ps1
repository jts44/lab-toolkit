<#
.SYNOPSIS
    clear-logon-notice.ps1 - Remove a stale "device not properly managed" logon message.
.DESCRIPTION
    Use only AFTER the device has been added to its building/area group and has
    synced, if the logon notice still appears. Deletes LegalNoticeCaption and
    LegalNoticeText under HKLM\...\Policies\System, then reboot.
    If the device is still ungrouped, policy will simply put the message back.
.NOTES
    Tier:    Modifies settings
    Tested:  Windows 10/11, PowerShell 5.1
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\clear-logon-notice.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param([switch]$Force)

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error 'Run from an elevated PowerShell session.'; exit 1
}

$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$p = Get-ItemProperty $key -ErrorAction SilentlyContinue
Write-Host "Caption: $($p.LegalNoticeCaption)"
Write-Host "Text:    $($p.LegalNoticeText)"

if (-not $Force -and -not $WhatIfPreference) {
    if ((Read-Host 'Clear these values? [y/N]') -notmatch '^[yY]') { exit 1 }
}
foreach ($v in 'LegalNoticeCaption', 'LegalNoticeText') {
    if ($PSCmdlet.ShouldProcess("$key\$v", 'Remove value')) {
        Remove-ItemProperty -Path $key -Name $v -ErrorAction SilentlyContinue
    }
}
Write-Host 'Cleared. Reboot to confirm the message is gone.'
