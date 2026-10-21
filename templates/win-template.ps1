<#
.SYNOPSIS
    <verb-noun>.ps1 - <one sentence>
.NOTES
    Tier:    Read-only | Modifies settings | Destructive
    Tested:  Windows <10/11 build>, PowerShell 5.1
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\<name>.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error 'Run from an elevated PowerShell session.'
        exit 1
    }
}

function Confirm-Action([string]$Message) {
    if ($Force -or $WhatIfPreference) { return }
    $r = Read-Host "$Message [y/N]"
    if ($r -notmatch '^[yY]') { exit 1 }
}

# --- main ---------------------------------------------------------
# Assert-Admin
# Confirm-Action 'Proceed?'
# if ($PSCmdlet.ShouldProcess('<target>', '<action>')) { <command> }
