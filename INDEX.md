# Script index

🟢 read-only · 🟡 modifies settings · 🔴 destructive

## macOS

### decommission
- `mac/decommission/remove-beyondtrust.sh` 🔴 Remove BeyondTrust EPM and adapter (run first)
- `mac/decommission/remove-jamf.sh` 🔴 Remove Jamf framework, Self Service, Jamf Connect, Conditional Access, receipts (re-runnable)
- `mac/decommission/verify.sh` 🟢 Report enrollment, profiles, loaded jobs, processes, and agent remnants (run after restart)

### mdm
### network
### system
### users
### apps

## Windows

### intune
- `win/intune/get-device-info.ps1` 🟢 Serial, Entra/AD join state, Intune enrollment, Autopilot profile, AD OU
- `win/intune/register-autopilot.ps1` 🟡 Upload Autopilot hardware hash to Intune (Path A: existing PC)
- `win/intune/sync-intune.ps1` 🟡 Force Intune check-in; optional gpupdate
- `win/intune/clear-logon-notice.ps1` 🟡 Remove stale "not properly managed" logon message after grouping

### network
### system
### users
### apps
