<#
.SYNOPSIS
    get-device-info.ps1 - Show identity, join, enrollment, and Autopilot state for this PC.
.DESCRIPTION
    Read-only. Gathers what you need to find the device in Entra/Intune/AD and
    to judge whether it enrolled correctly: serial, hostname, Entra device ID,
    join type (Entra / hybrid / domain), MDM enrollment, Autopilot profile,
    AD OU, and Intune Management Extension status.
.NOTES
    Tier:    Read-only
    Tested:  Windows 10/11, PowerShell 5.1
.EXAMPLE
    irm https://spieles.us/win/intune/get-device-info.ps1 | iex
#>

function Get-DsregValue([string[]]$Lines, [string]$Key) {
    $l = $Lines | Where-Object { $_ -match "^\s*$Key\s*:" } | Select-Object -First 1
    if ($l) { return ($l -split ':', 2)[1].Trim() } else { return '' }
}

$cs     = Get-CimInstance Win32_ComputerSystem
$bios   = Get-CimInstance Win32_BIOS
$os     = Get-CimInstance Win32_OperatingSystem
$dsreg  = & dsregcmd.exe /status 2>$null

$info = [ordered]@{
    'Computer name'     = $env:COMPUTERNAME
    'Serial / tag'      = $bios.SerialNumber
    'Model'             = "$($cs.Manufacturer) $($cs.Model)"
    'OS'                = "$($os.Caption) $($os.Version)"
    'Entra joined'      = Get-DsregValue $dsreg 'AzureAdJoined'
    'Domain joined'     = Get-DsregValue $dsreg 'DomainJoined'
    'Domain'            = Get-DsregValue $dsreg 'DomainName'
    'Entra device ID'   = Get-DsregValue $dsreg 'DeviceId'
    'Tenant'            = Get-DsregValue $dsreg 'TenantName'
    'MDM URL'           = Get-DsregValue $dsreg 'MdmUrl'
}

# Join type summary
$aad = $info['Entra joined'] -eq 'YES'; $dom = $info['Domain joined'] -eq 'YES'
$info['Join type'] = if ($aad -and $dom) { 'Hybrid (Entra + AD)' }
                     elseif ($aad) { 'Entra joined' }
                     elseif ($dom) { 'AD only (not Entra joined)' }
                     else { 'Workgroup' }

# MDM enrollment (Intune)
$enr = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue |
       Get-ItemProperty -ErrorAction SilentlyContinue |
       Where-Object { $_.ProviderID -eq 'MS DM Server' } | Select-Object -First 1
$info['Intune enrolled'] = if ($enr) { "Yes ($($enr.UPN))" } else { 'No' }

# Autopilot profile received?
$ap = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\Autopilot' -ErrorAction SilentlyContinue
$info['Autopilot profile'] = if ($ap -and $ap.CloudAssignedTenantDomain) {
    "Yes (tenant $($ap.CloudAssignedTenantDomain))" } else { 'None received' }

# AD OU (needs line of sight to a domain controller)
if ($dom) {
    try {
        $s = [adsisearcher]"(&(objectCategory=computer)(name=$env:COMPUTERNAME))"
        $info['AD location'] = [string]$s.FindOne().Properties['distinguishedname'][0]
    } catch { $info['AD location'] = 'Unavailable (no DC reachable?)' }
}

# Intune Management Extension (Win32 apps, scripts)
$ime = Get-Service IntuneManagementExtension -ErrorAction SilentlyContinue
$info['IME service'] = if ($ime) { $ime.Status } else { 'Not installed' }

$info.GetEnumerator() | ForEach-Object { '{0,-18} {1}' -f $_.Key, $_.Value }
