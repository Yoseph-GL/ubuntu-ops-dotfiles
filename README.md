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

## Maintenance

### `update-all`

Updates packages (`apt`, `snap`, `flatpak`) and writes package state snapshots.

```bash
./maintenance/update-all --run
./maintenance/update-all --run --backup-dir "$HOME/Backups/Snapshots/Config_Dumps"
```

### `maintenance-all`

Orchestrates:
1. `update-all`
2. `disk-clean-safe --deep-system-clean`

```bash
./maintenance/maintenance-all --run
./maintenance/maintenance-all --run --days 30
./maintenance/maintenance-all --run --backup-dir "$HOME/Backups/Snapshots"
```

### `disk-clean-safe`

Safe cleanup of user-space reclaimable data (trash, cache, and old temporary files).

Note: `--deep-system-clean` performs I/O-intensive operations (including journal vacuum) and may take several minutes to complete. This is expected behavior.

```bash
./system/disk-clean-safe --run
./system/disk-clean-safe --run --days 30
./system/disk-clean-safe --run --deep-system-clean
```

### `docker-clean-safe`

Safe cleanup of unused Docker artifacts.

```bash
./docker/docker-clean-safe --run
./docker/docker-clean-safe --run --with-volumes
```

## Backups

### `backup-skeleton`

Creates a directory-structure-only snapshot of `$HOME` (no files).
Includes a max-depth failsafe of 6 levels and excludes `Backups/` to avoid recursive destination capture.

```bash
./setup_and_backup/backup-skeleton --run
./setup_and_backup/backup-skeleton --run --dest "$HOME/Backups/Snapshots" --name home-skeleton
```

### `restore-skeleton`

Recreates directory structure from a snapshot located under `$HOME/Backups/Snapshots`.

```bash
./setup_and_backup/restore-skeleton --from "$HOME/Backups/Snapshots/home-skeleton" --to "$HOME/test-restore" --run
```

## Diagnostics

### `health-check`

Quick host diagnostics (system, memory, disk, services, and common ports).

```bash
./system/health-check --run
```

### `net-debug`

Network diagnostics (IPs, default route, DNS, pings, and ports).

```bash
./network/net-debug --run
./network/net-debug --run --host github.com
```

### `check-logs.sh`

Extended system/log diagnostics.

```bash
./system/check-logs.sh --run
```

### `docker-net-audit.sh`

Docker network mapping audit (veth/container/bridge) and detection of networks without active containers.

```bash
./docker/docker-net-audit.sh --run
```

## Tooling

### `install-direnv-just-k6`

Configures the official k6 repository and installs `direnv`, `just`, and `k6`.
k6 is used for performance testing by running JavaScript load scenarios (for example, `k6 run ./perf/smoke.js`).

```bash
./setup_and_backup/install-direnv-just-k6 --run
```

### `lint-scripts`

Validates shell syntax (`bash -n`) and runs `shellcheck` when installed.

```bash
./maintenance/lint-scripts --run
```

## Quick Start

```bash
cd "$HOME/Workspace/ops/scripts"
```
