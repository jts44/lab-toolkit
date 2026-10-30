<#
.SYNOPSIS
    sync-intune.ps1 - Force an Intune check-in (and optionally Group Policy).
.DESCRIPTION
    Equivalent to Settings > Accounts > Access work or school > Info > Sync.
    Starts the MDM PushLaunch scheduled task, restarts the Intune Management
    Extension (Win32 apps/scripts), and with -GroupPolicy runs gpupdate /force.
    Syncing does not speed up Entra group membership or profile assignment;
    it only makes the PC pick up changes that already exist in the cloud.
.NOTES
    Tier:    Modifies settings (triggers check-in; no config changes)
    Tested:  Windows 10/11, PowerShell 5.1
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\sync-intune.ps1 -GroupPolicy
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param([switch]$GroupPolicy)

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error 'Run from an elevated PowerShell session.'; exit 1
}

$tasks = Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -ErrorAction SilentlyContinue |
         Where-Object TaskName -eq 'PushLaunch'
if (-not $tasks) {
    Write-Warning 'No MDM PushLaunch task found: this PC does not appear to be enrolled in Intune.'
} else {
    foreach ($t in $tasks) {
        if ($PSCmdlet.ShouldProcess($t.TaskPath, 'Start MDM sync')) { $t | Start-ScheduledTask }
    }
    Write-Host '-> MDM sync triggered'
}

if (Get-Service IntuneManagementExtension -ErrorAction SilentlyContinue) {
    if ($PSCmdlet.ShouldProcess('IntuneManagementExtension', 'Restart service')) {
        Restart-Service IntuneManagementExtension -Force
        Write-Host '-> Intune Management Extension restarted'
    }
}

if ($GroupPolicy -and $PSCmdlet.ShouldProcess('Group Policy', 'gpupdate /force')) {
    gpupdate /force
}

Write-Host 'Done. Policies and apps can take 15-30 minutes to apply after a sync.'
