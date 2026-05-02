#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
MODE="dry-run"

WARNING_EXCLUDES='tpm|i8042|IMA|SUBNQN|bluetooth|jackdbus|orca|csip|micp|vcp|mcp|bass|bap|apt-daily|fstrim|logrotate|dpkg-db|avahi|ModemManager|pool-gnome|UFW BLOCK|colord|camera|evolution|at-spi2|GUnixInputStream|ding@raster|Gdm.*REMOTE|wireplumber|gsd-media-keys|amdgpu.*psp|SECUREDISPLAY|dashtodock|DashSlideContainer|DashToDock|StBoxLayout|MetaBackground|StWidget|bms-dash'
ERROR_EXCLUDES='tpm|i8042|IMA|SUBNQN|bluetooth|jackdbus|avahi|ModemManager|amdgpu.*psp|SECUREDISPLAY|UFW|colord|ding@raster|at-spi2|GUnixInputStream|dashtodock|nftables.*docker-bridges'
KERNEL_EXCLUDES='tpm|i8042|IMA|SUBNQN|amdgpu.*psp|SECUREDISPLAY'

usage() {
  cat <<'USAGE'
Usage: check-logs.sh [--run]

Extended diagnostics report:
- boot performance and failed units
- filtered journal warnings and errors
- slow services, crash reports, memory
- OOM, docker/service/auth related events

Default mode is dry-run. Use --run to execute.
USAGE
}

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_err() { printf '[ERROR] %s\n' "$*" >&2; }
die() { log_err "$*"; exit 1; }

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

reject_run_flag_typo() {
  local arg="$1"
  if [[ "$arg" != "--run" && "$arg" =~ ^[-/]+[Rr][Uu][Nn]$ ]]; then
    die "Invalid execution flag '$arg'. Use exactly --run."
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    reject_run_flag_typo "$1"
    case "$1" in
      --run)
        MODE="run"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

check_dependencies() {
  require_cmd systemd-analyze
  require_cmd systemctl
  require_cmd journalctl
  require_cmd grep
  require_cmd tail
  require_cmd free
  require_cmd awk
  require_cmd date
  require_cmd wc
}

print_plan() {
  echo "=== CHECK LOGS ==="
  echo "Script path: $SCRIPT_DIR"
  echo "Mode: $MODE"
  echo
  echo "Would run sections:"
  echo "  [BOOT PERFORMANCE] [FAILED UNITS] [WARNINGS] [ERRORS] [SLOW SERVICES]"
  echo "  [CRASH REPORTS] [MEMORY/SWAP] [OOM] [DOCKER] [SECURITY] [SUMMARY]"
}

print_section() {
  local title="$1"
  echo
  echo "--- $title ---"
}

run_or_note() {
  local description="$1"
  shift
  if ! "$@"; then
    log_warn "$description returned a non-zero status"
  fi
}

count_kernel_errors() {
  local count=0
  if command -v dmesg >/dev/null 2>&1; then
    count="$(dmesg --level=err,crit --human 2>/dev/null | grep -v -E "$KERNEL_EXCLUDES" | grep -c . || true)"
  else
    log_warn "dmesg not available; kernel error count is 0"
  fi
  echo "$count"
}

execute_dry_run() {
  print_plan
  echo
  echo "Dry-run only. Re-run with --run to execute."
}

execute_real() {
  check_dependencies
  print_plan
  echo
  echo "Diagnostics timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"

  print_section "BOOT PERFORMANCE"
  systemd-analyze

  print_section "FAILED UNITS"
  systemctl --failed --no-pager

  print_section "FILTERED WARNINGS"
  journalctl -b -p warning --no-pager 2>/dev/null \
    | grep -v -E "$WARNING_EXCLUDES" \
    | tail -20

  print_section "FILTERED CRITICAL ERRORS"
  journalctl -b -p err --no-pager 2>/dev/null \
    | grep -v -E "$ERROR_EXCLUDES" \
    | tail -20

  print_section "SLOWEST SERVICES"
  systemd-analyze blame --no-pager 2>/dev/null | head -10

  print_section "CRASH REPORTS"
  local crash_count
  crash_count="$(find /var/crash -maxdepth 1 -type f -name '*.crash' 2>/dev/null | wc -l || true)"
  if [[ "$crash_count" == "0" ]]; then
    echo "No crash reports found."
  else
    echo "$crash_count crash report(s) in /var/crash/"
    find /var/crash -maxdepth 1 -type f -name '*.crash' 2>/dev/null
  fi

  print_section "MEMORY AND SWAP"
  free -h

  print_section "OOM EVENTS"
  if ! journalctl -b --no-pager 2>/dev/null \
    | grep -iE '^.*killed process|out of memory' \
    | tail -5; then
    echo "No OOM events found."
  fi

  print_section "DOCKER EVENTS"
  if ! journalctl -b -u docker --no-pager 2>/dev/null \
    | grep -iE 'error|fail|panic' \
    | grep -v 'nftables.*docker-bridges' \
    | tail -5; then
    echo "No docker errors found."
  fi

  print_section "SECURITY EVENTS"
  if ! journalctl -b --no-pager 2>/dev/null \
    | grep -iE 'authentication failure|failed password|invalid user' \
    | tail -5; then
    echo "No authentication failures found."
  fi

  print_section "SUMMARY"
  printf '%-30s %s\n' "Kernel errors (filtered):" "$(count_kernel_errors)"
  printf '%-30s %s\n' "Warnings (filtered):" \
    "$(journalctl -b -p warning --no-pager 2>/dev/null | grep -v -E "$WARNING_EXCLUDES" | grep -c .)"
  printf '%-30s %s\n' "Failed units:" \
    "$(systemctl --failed --no-pager | grep -c 'failed' 2>/dev/null || echo "0")"
  printf '%-30s %s\n' "Crash reports:" "$crash_count"
}

main() {
  trap 'log_err "Failed at line $LINENO: $BASH_COMMAND"' ERR
  parse_args "$@"
  if [[ "$MODE" == "run" ]]; then
    execute_real
  else
    execute_dry_run
  fi
}

main "$@"
