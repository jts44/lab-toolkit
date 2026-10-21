#!/bin/zsh
# ------------------------------------------------------------------
# Name:        remove-jamf.sh
# Purpose:     Remove Jamf Pro framework, Self Service, and residual files
#              after the MDM profile has been removed.
# Tier:        🔴 Destructive
# Tested:      macOS 13–15
# Usage:       sudo zsh remove-jamf.sh [--dry-run] [-y]
# Notes:       Does NOT release the device from ABM/ASM; do that in the
#              Apple School/Business Manager portal before erasing.
#              Remove BeyondTrust EPM first if it blocks sudo.
# ------------------------------------------------------------------

set -u
setopt NULL_GLOB   # unmatched globs expand to nothing instead of erroring
DRY_RUN=0; ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;; -y|--yes) ASSUME_YES=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
  esac
done
run() { if (( DRY_RUN )); then print "[dry-run] $*"; else "$@"; fi; }
[[ $EUID -eq 0 ]] || { print -u2 "Run with sudo."; exit 1; }
if ! (( ASSUME_YES || DRY_RUN )); then
  read -q "?Remove all Jamf components from this Mac? [y/N] " || { print; exit 1; }; print
fi

# 1. Jamf Connect: reset login window BEFORE removing anything
if [[ -x /usr/local/bin/authchanger ]]; then
  print "→ Resetting login window (Jamf Connect)"
  run /usr/local/bin/authchanger -reset
fi

# 2. Built-in uninstaller
if [[ -x /usr/local/bin/jamf ]]; then
  print "→ Running jamf removeFramework"
  run /usr/local/bin/jamf removeFramework
fi

# 3. Launchd jobs
print "→ Unloading launch daemons/agents"
for p in /Library/LaunchDaemons/com.jamf* /Library/LaunchAgents/com.jamf*(N); do
  run launchctl bootout system "$p" 2>/dev/null
  run rm -f "$p"
done

# 4. Processes
run pkill -i -f jamf 2>/dev/null
run pkill -f "Self Service" 2>/dev/null

# 5. Files and apps
print "→ Removing files"
run rm -rf \
  /usr/local/jamf \
  /usr/local/bin/jamf /usr/local/bin/jamfAgent /usr/local/bin/authchanger \
  "/Library/Application Support/JAMF" \
  "/Applications/Self Service.app" "/Applications/Self Service+.app" \
  "/Applications/Jamf Connect.app" \
  /Library/Preferences/com.jamfsoftware.* \
  /private/var/log/jamf.log

# 6. Per-user preferences and caches
for u in /Users/*(N/); do
  run rm -rf "$u"/Library/Preferences/com.jamfsoftware.*(N) \
             "$u"/Library/Caches/com.jamfsoftware.*(N)
done

# 7. Package receipts
for r in $(pkgutil --pkgs | grep -i jamf); do run pkgutil --forget "$r"; done

print "✓ Done. Run verify.sh to confirm."
