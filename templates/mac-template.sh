#!/bin/zsh
# ------------------------------------------------------------------
# Name:        <verb-noun>.sh
# Purpose:     <one sentence>
# Tier:        🟢 Read-only | 🟡 Modifies settings | 🔴 Destructive
# Tested:      macOS <version>, <Intel/Apple silicon>
# Usage:       sudo zsh <name>.sh [--dry-run] [-y]
# ------------------------------------------------------------------

set -u

DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -y|--yes)  ASSUME_YES=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
  esac
done

# Run a command, or print it in dry-run mode
run() {
  if (( DRY_RUN )); then print "[dry-run] $*"; else "$@"; fi
}

require_root() {
  [[ $EUID -eq 0 ]] || { print -u2 "Run with sudo."; exit 1; }
}

confirm() {
  (( ASSUME_YES || DRY_RUN )) && return 0
  read -q "?$1 [y/N] " || { print; exit 1; }
  print
}

# --- main ---------------------------------------------------------
# require_root
# confirm "Proceed?"
# run <command>
