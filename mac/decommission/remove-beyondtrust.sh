#!/bin/zsh
# ------------------------------------------------------------------
# Name:        remove-beyondtrust.sh
# Purpose:     Remove BeyondTrust Endpoint Privilege Management (Avecto)
#              and its management adapter using vendor uninstall scripts.
# Tier:        🔴 Destructive
# Tested:      macOS 13–15
# Usage:       sudo zsh remove-beyondtrust.sh [--dry-run] [-y]
# Source:      https://docs.beyondtrust.com/epm-wm/docs/uninstall-epm-clients-and-adapters
# Notes:       Remote Support Jump Clients (bomgar-scc / sra-scc) are best
#              removed from the BeyondTrust representative console.
# ------------------------------------------------------------------

set -u
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
  read -q "?Remove BeyondTrust EPM from this Mac? [y/N] " || { print; exit 1; }; print
fi

EPM=/usr/local/libexec/Avecto/Defendpoint/1.0/uninstall.sh
ADAPTER=/usr/local/libexec/Avecto/iC3Adapter/1.0/uninstall_ic3_adapter.sh

if [[ -x $ADAPTER ]]; then
  print "→ Removing management adapter"; run "$ADAPTER"
fi
if [[ -x $EPM ]]; then
  print "→ Removing Endpoint Privilege Management"; run "$EPM"
else
  print "  EPM uninstaller not found (already removed?)"
fi

# Leftovers the vendor script leaves when directories are non-empty
run rm -rf "/Library/Application Support/Avecto"

# Report any Remote Support Jump Client remnants (not auto-deleted)
print "→ Checking for Remote Support Jump Client remnants"
find /Library /Users/Shared -maxdepth 3 \
  \( -iname '*bomgar*' -o -iname '*sra-scc*' \) 2>/dev/null

print "✓ Done. Run verify.sh to confirm."
