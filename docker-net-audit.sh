#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
MODE="dry-run"

usage() {
  cat <<'USAGE'
Usage: docker-net-audit.sh [--run]

Docker network audit:
- container eth interface -> host veth -> bridge mapping
- docker networks without active containers

Default mode is dry-run. Use --run to execute.
USAGE
}

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
  require_cmd docker
  require_cmd nsenter
  require_cmd ip
  require_cmd awk
  require_cmd grep
  require_cmd cut
  require_cmd tr
}

print_plan() {
  echo "=== DOCKER NET AUDIT ==="
  echo "Script path: $SCRIPT_DIR"
  echo "Mode: $MODE"
  echo
  echo "Would run:"
  echo "  1) Map veth -> container -> docker bridge"
  echo "  2) List docker networks without active containers"
}

audit_veth_map() {
  echo
  echo "CONTAINER ETH TO HOST VETH MAP"
  echo "----------------------------------------"

  local cid name pid line ethname peer_idx host_veth master net_id net_name
  while IFS= read -r cid; do
    [[ -n "$cid" ]] || continue
    name="$(docker inspect -f '{{.Name}}' "$cid" | tr -d '/')"
    pid="$(docker inspect -f '{{.State.Pid}}' "$cid")"
    echo "-- $name --"

    while IFS= read -r line; do
      ethname="$(grep -oP 'eth\d+' <<<"$line")"
      peer_idx="$(grep -oP '@if\K\d+' <<<"$line")"
      host_veth="$(ip -o link | awk -v idx="$peer_idx" '$1 == idx":" {print $2}' | cut -d@ -f1)"
      master="$(ip link show "$host_veth" 2>/dev/null | grep -oP 'master \K\S+' || true)"
      net_name=""
      if [[ -n "$master" ]]; then
        net_id="${master#br-}"
        net_name="$(docker network ls --no-trunc --format '{{.ID}} {{.Name}}' | awk -v id="$net_id" '$1 ~ "^"id {print $2}')"
      fi
      echo "  $ethname -> $host_veth -> $master [$net_name]"
    done < <(nsenter -t "$pid" -n ip link 2>/dev/null | grep -E '^[0-9]+: eth')
  done < <(docker ps -q)
}

list_unused_networks() {
  echo
  echo "DOCKER NETWORKS WITHOUT ACTIVE CONTAINERS"
  echo "----------------------------------------"

  local id name count
  docker network ls --format '{{.ID}} {{.Name}}' | while IFS= read -r id name; do
    [[ -n "$id" ]] || continue
    count="$(docker network inspect "$id" --format '{{len .Containers}}')"
    if [[ "$count" -eq 0 && "$name" != "bridge" && "$name" != "host" && "$name" != "none" ]]; then
      echo "  $name ($id) has no active containers"
    fi
  done
}

execute_dry_run() {
  print_plan
  echo
  echo "Dry-run only. Re-run with --run to execute."
}

execute_real() {
  check_dependencies
  print_plan
  audit_veth_map
  list_unused_networks
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
