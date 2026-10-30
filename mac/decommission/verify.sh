#!/bin/zsh
# ------------------------------------------------------------------
# Name:        verify.sh
# Purpose:     Report remaining MDM enrollment, profiles, and Jamf/
#              BeyondTrust components. Run after a restart.
# Tier:        🟢 Read-only
# Tested:      macOS 13–15
# Usage:       sudo zsh verify.sh
# ------------------------------------------------------------------

setopt NULL_GLOB
[[ $EUID -eq 0 ]] || print -u2 "Tip: run with sudo for complete results."

PAT='jamf|avecto|beyondtrust|bomgar|sra-scc'
hdr() { print "\n== $1 =="; }

hdr "MDM enrollment (expect: No / No)"
profiles status -type enrollment 2>&1

hdr "Configuration profiles"
profiles list -all 2>&1

hdr "Jamf binary"
command -v jamf || print "none"

hdr "Running processes"
ps -axo pid=,command= | grep -Ei "$PAT|self service" | grep -v grep || print "none"

hdr "Loaded launchd jobs (system + GUI sessions)"
{
  launchctl print system 2>/dev/null
  for uid in ${(u)$(ps -axo uid=,comm= | awk '/loginwindow$/ {print $1}')}; do
    launchctl print "gui/$uid" 2>/dev/null
  done
} | grep -Eio "com\.(jamf|jamfsoftware|bomgar|beyondtrust|avecto)[^ ]*" | sort -u || true
print "(blank above = none)"

hdr "Launch daemon/agent files"
ls /Library/LaunchDaemons /Library/LaunchAgents 2>/dev/null | grep -Ei "$PAT" || print "none"

hdr "Package receipts"
pkgutil --pkgs | grep -Ei "$PAT" || print "none"

hdr "System extensions"
systemextensionsctl list 2>/dev/null | grep -Ei "$PAT" || print "none"

hdr "Applications"
ls /Applications | grep -Ei "self service|jamf|beyondtrust" || print "none"

hdr "Residual paths"
found=0
for p in /usr/local/jamf /usr/local/bin/jamf /usr/local/bin/authchanger \
         "/Library/Application Support/JAMF" \
         /Library/Preferences/com.jamfsoftware.* /Library/Preferences/com.jamf.* \
         /usr/local/libexec/Avecto "/Library/Application Support/Avecto"; do
  [[ -e $p ]] && { print "PRESENT: $p"; found=1; }
done
(( found )) || print "none"

print "\nAlso check manually:"
print "  • System Settings → General → Device Management (no profiles)"
print "  • System Settings → General → Login Items & Extensions (no Jamf items)"
print "  • Entra ID / Intune device record retired (if Conditional Access was used)"
print "Before resale: release serial in ABM/ASM, sign out of Apple ID, Erase All Content and Settings."
