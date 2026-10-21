#!/bin/zsh
# ------------------------------------------------------------------
# Name:        verify.sh
# Purpose:     Report remaining MDM enrollment, profiles, and Jamf/
#              BeyondTrust components before resale.
# Tier:        🟢 Read-only
# Tested:      macOS 13–15
# Usage:       sudo zsh verify.sh
# ------------------------------------------------------------------

[[ $EUID -eq 0 ]] || { print -u2 "Run with sudo for complete results."; }

PAT='jamf|avecto|beyondtrust|bomgar|sra-scc'
hdr() { print "\n== $1 =="; }

hdr "ADE/DEP enrollment"
profiles show -type enrollment 2>&1 | head -20

hdr "Installed configuration profiles"
profiles list -all 2>&1

hdr "Package receipts"
pkgutil --pkgs | grep -Ei "$PAT" || print "none"

hdr "Launch daemons/agents"
ls /Library/LaunchDaemons /Library/LaunchAgents 2>/dev/null | grep -Ei "$PAT" || print "none"

hdr "System extensions"
systemextensionsctl list 2>/dev/null | grep -Ei "$PAT" || print "none"

hdr "Applications"
ls /Applications | grep -Ei "self service|jamf|beyondtrust" || print "none"

hdr "Residual paths"
for p in /usr/local/jamf /usr/local/bin/jamf "/Library/Application Support/JAMF" \
         /usr/local/libexec/Avecto "/Library/Application Support/Avecto"; do
  [[ -e $p ]] && print "PRESENT: $p"
done

print "\nReminder: release serial from ABM/ASM, delete Jamf Pro record, sign out of Apple ID, then Erase All Content and Settings."
