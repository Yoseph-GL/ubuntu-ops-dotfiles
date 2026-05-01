# Ops Scripts

Collection of operations scripts for local maintenance, snapshots, and diagnostics.

## Manual-Safe Policy

All scripts follow a strict manual-safe model:

- Without flags, scripts always run in `dry-run` mode.
- Real execution requires `--run`.
- Zero tolerance for execution-flag typos (`-run`, `/run`, etc.): scripts abort with an error and exit code `1`.
- Scripts use `set -euo pipefail` and dependency checks.
- All scripts anchor runtime context with `SCRIPT_DIR`.

## Backup Paths Policy

Backup paths are restricted to:

- `$HOME/Backups/Snapshots`
- `$HOME/Backups/Snapshots/Config_Dumps`

Scripts safely create required destination directories with `mkdir -p`.

## Maintenance and Cleanup

### `update-all`

Updates packages (`apt`, `snap`, `flatpak`) and writes package state snapshots.

```bash
./update-all
./update-all --run
./update-all --run --backup-dir "$HOME/Backups/Snapshots/Config_Dumps"
```

### `maintenance-all`

Orchestrates:
1. `update-all`
2. `disk-clean-safe --deep-system-clean`

```bash
./maintenance-all
./maintenance-all --run
./maintenance-all --run --days 30
./maintenance-all --run --backup-dir "$HOME/Backups/Snapshots"
```

### `disk-clean-safe`

Safe cleanup of user-space reclaimable data (trash, cache, and old temporary files).

Note: `--deep-system-clean` performs I/O-intensive operations (including journal vacuum) and may take several minutes to complete. This is expected behavior.

```bash
./disk-clean-safe
./disk-clean-safe --run
./disk-clean-safe --run --days 30
./disk-clean-safe --run --deep-system-clean
```

### `docker-clean-safe`

Safe cleanup of unused Docker artifacts.

```bash
./docker-clean-safe
./docker-clean-safe --run
./docker-clean-safe --run --with-volumes
```

## Backups and Snapshots

### `backup-skeleton`

Creates a directory-structure-only snapshot of `$HOME` (no files).
Includes a max-depth failsafe of 6 levels and excludes `Backups/` to avoid recursive destination capture.

```bash
./backup-skeleton
./backup-skeleton --run
./backup-skeleton --run --dest "$HOME/Backups/Snapshots" --name home-skeleton
```

### `restore-skeleton`

Recreates directory structure from a snapshot located under `$HOME/Backups/Snapshots`.

```bash
./restore-skeleton --from "$HOME/Backups/Snapshots/home-skeleton"
./restore-skeleton --from "$HOME/Backups/Snapshots/home-skeleton" --to "$HOME/test-restore" --run
```

## Diagnostics

### `health-check`

Quick host diagnostics (system, memory, disk, services, and common ports).

```bash
./health-check
./health-check --run
```

### `net-debug`

Network diagnostics (IPs, default route, DNS, pings, and ports).

```bash
./net-debug
./net-debug --run
./net-debug --run --host github.com
```

### `check-logs.sh`

Extended system/log diagnostics.

```bash
./check-logs.sh
./check-logs.sh --run
```

### `docker-net-audit.sh`

Docker network mapping audit (veth/container/bridge) and detection of networks without active containers.

```bash
./docker-net-audit.sh
./docker-net-audit.sh --run
```

## Tooling

### `install-direnv-just-k6`

Configures the official k6 repository and installs `direnv`, `just`, and `k6`.

```bash
./install-direnv-just-k6
./install-direnv-just-k6 --run
```

### `lint-scripts`

Validates shell syntax (`bash -n`) and runs `shellcheck` when installed.

```bash
./lint-scripts
./lint-scripts --run
```

## Quick Start

```bash
cd "$HOME/Workspace/ops/scripts"
```
