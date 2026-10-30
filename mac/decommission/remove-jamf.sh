#!/bin/zsh
# ------------------------------------------------------------------
# Name:        remove-jamf.sh
# Purpose:     Remove Jamf Pro framework, Self Service, Jamf Connect,
#              legacy Jamf Conditional Access (jamfAAD), and residual
#              files after the Mac is authorized for removal from Jamf.
# Tier:        🔴 Destructive
# Tested:      macOS 13–15
# Usage:       sudo zsh remove-jamf.sh [--dry-run] [-y]
# Notes:       Safe to re-run; each step skips what is already gone.
#              Does NOT release the device from ABM/ASM or remove the
#              Microsoft Entra ID / Intune device record.
#              Remove BeyondTrust EPM first if it blocks sudo.
#              Restart when finished.
# Docs:        docs/remove-jamf-mac.md
# ------------------------------------------------------------------

set -u
setopt NULL_GLOB   # unmatched globs expand to nothing instead of erroring
DRY_RUN=0; ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;; -y|--yes) ASSUME_YES=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
  esac
done
run() { if (( DRY_RUN )); then print "[dry-run] $*"; else "$@"; fi; }
[[ $EUID -eq 0 ]] || { print -u2 "Run with sudo."; exit 1; }
if ! (( ASSUME_YES || DRY_RUN )); then
  read -q "?Remove all Jamf components from this Mac? [y/N] " || { print; exit 1; }; print
fi

JAMF_SUPPORT="/Library/Application Support/JAMF"

# UIDs with an active GUI session (one loginwindow process per session)
gui_uids=( ${(u)$(ps -axo uid=,comm= | awk '/loginwindow$/ {print $1}')} )

# 1. Jamf Connect: reset login window BEFORE removing anything,
#    otherwise the login window can be left pointing at missing plugins.
if [[ -x /usr/local/bin/authchanger ]]; then
  print "→ Resetting login window (Jamf Connect)"
  run /usr/local/bin/authchanger -reset
fi

# 2. Built-in uninstaller (framework, daemons, Self Service)
if [[ -x /usr/local/bin/jamf ]]; then
  print "→ Running jamf removeFramework"
  run /usr/local/bin/jamf removeFramework
fi

# 3. Unload launchd jobs.
#    Daemons live in the system domain. Agents (Conditional Access,
#    Jamf Connect menu bar, JamfAgent) run inside each user's GUI
#    session, so they must be booted out of gui/<uid>. Booting out by
#    label also stops jobs whose plist was already deleted, which is
#    why Conditional Access can keep nagging after removeFramework.
print "→ Unloading launch daemons"
for p in /Library/LaunchDaemons/com.jamf*.plist; do
  run launchctl bootout system "$p" 2>/dev/null
done

print "→ Unloading launch agents in ${#gui_uids} GUI session(s)"
labels=( com.jamf.management.jamfAAD.agent com.jamf.management.jamfAAD.clean.agent )
for p in /Library/LaunchAgents/com.jamf*.plist; do labels+=( ${p:t:r} ); done
for uid in $gui_uids; do
  for label in ${(u)labels}; do
    run launchctl bootout "gui/$uid/$label" 2>/dev/null
  done
done

run rm -f /Library/LaunchDaemons/com.jamf*.plist /Library/LaunchAgents/com.jamf*.plist

# 4. Stop remaining processes (Self Service, Conditional Access, JamfAgent)
print "→ Stopping Jamf processes"
run pkill -i -f "Jamf Conditional Access" 2>/dev/null
run pkill -i -f "Self Service" 2>/dev/null
run pkill -i -f jamf 2>/dev/null

# 5. Files and apps
#    $JAMF_SUPPORT contains Jamf.app, which bundles both
#    "Jamf Conditional Access.app" and JamfAgent.app.
print "→ Removing files"
run rm -rf \
  /usr/local/jamf \
  /usr/local/bin/jamf /usr/local/bin/jamfAgent /usr/local/bin/authchanger \
  "$JAMF_SUPPORT" \
  "/Applications/Self Service.app" "/Applications/Self Service+.app" \
  "/Applications/Jamf Connect.app" \
  /Library/Preferences/com.jamfsoftware.* \
  /Library/Preferences/com.jamf.* \
  /private/var/log/jamf.log

# 6. Per-user preferences and caches
for u in /Users/*(N/); do
  run rm -rf "$u"/Library/Preferences/com.jamfsoftware.* \
             "$u"/Library/Preferences/com.jamf.* \
             "$u"/Library/Caches/com.jamfsoftware.* \
             "$u"/Library/Caches/com.jamf.*
done

# 7. Package receipts
for r in $(pkgutil --pkgs | grep -i jamf); do run pkgutil --forget "$r"; done

print "✓ Done."
print "  Next: restart (sudo shutdown -r now), then run verify.sh."
print "  Microsoft Entra ID / Intune records and keychain items are not touched;"
print "  see docs/remove-jamf-mac.md if Conditional Access prompts continue."
