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
  require_cmd sudo
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

  local cid name pid iflink target_index host_veth master net_id net_name
  while IFS= read -r cid; do
    [[ -n "$cid" ]] || continue
    name="$(docker inspect -f '{{.Name}}' "$cid" | tr -d '/')"
    pid="$(docker inspect -f '{{.State.Pid}}' "$cid")"
    echo "-- $name --"

    if [[ "$pid" == "0" ]]; then
      echo "  eth0 -> unavailable (container is not running)"
      continue
    fi

    iflink=$(sudo -n nsenter -t "$pid" -n bash -c 'for d in /sys/class/net/*; do if [ "${d##*/}" != "lo" ]; then cat "$d/iflink" 2>/dev/null && break; fi; done')
    if [[ -z "$iflink" ]]; then
      echo "  eth0 -> unavailable (host network mode or interface not present)"
      continue
    fi

    # The host-side veth index is what the container's eth0 considers its 'link' (peer)
    target_index=$(sudo -n nsenter -t "$pid" -n ethtool -S eth0 2>/dev/null | grep peer_ifindex | awk '{print $2}')
    if [[ -z "$target_index" ]]; then
        # Fallback if ethtool is missing: use the iflink directly
        target_index="$iflink"
    fi
    host_veth=$(ip -o link show | grep "^$target_index:" | sed -n 's/.* \(veth[^@]*\)@.*/\1/p')
    if [[ -z "$host_veth" ]]; then
      echo "  eth0 iflink $iflink -> veth mapping failed"
      continue
    fi

    master="$(ip -o link show "$host_veth" 2>/dev/null | awk 'match($0, /master ([^ ]+)/, m) {print m[1]}')"
    net_name=""
    if [[ -n "$master" && "$master" == br-* ]]; then
      net_id="${master#br-}"
      net_name="$(docker network ls --no-trunc --format '{{.ID}} {{.Name}}' | awk -v id="$net_id" '$1 ~ "^"id {print $2; exit}')"
    fi
    echo "  eth0 iflink $iflink -> $host_veth -> ${master:-no-master} [${net_name:-unmapped}]"
  done < <(docker ps -q)
}

list_unused_networks() {
  echo
  echo "DOCKER NETWORKS WITHOUT ACTIVE CONTAINERS"
  echo "----------------------------------------"

  local net_id net_name containers
  docker network ls --format '{{.ID}} {{.Name}}' | while read -r net_id net_name; do
    [[ -n "$net_id" ]] || continue
    if [[ "$net_name" == "bridge" || "$net_name" == "host" || "$net_name" == "none" ]]; then
      continue
    fi

    if ! containers="$(docker network inspect "$net_id" -f '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)"; then
      echo "  Network: $net_name ($net_id) could not be inspected."
      continue
    fi

    if [[ -z "$containers" ]]; then
      echo "  Network: $net_name ($net_id) has no active containers."
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
