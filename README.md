# Ops Scripts

Personal operations scripts for local maintenance and diagnostics.

## Safety Model

All scripts are **manual-safe**:

- Default mode is **dry-run** (preview only).
- Real execution requires `--run`.
- Scripts include explicit dependency/error checks.
- Critical wrappers use `flock` locking to avoid overlapping runs.

This keeps routine operations explicit and low-risk.

## Available Scripts

### `update-all`

Updates system/app packages (`apt`, `flatpak`, `snap`) and writes package snapshots.

Notes:
- Uses `apt-get` for script-safe automation behavior.
- Saves before/after snapshots for apt and snap pending updates.
- Uses lock file protection against concurrent execution.

```bash
./update-all
./update-all --run
./update-all --run --backup-dir "$HOME/Backups/Snapshots/Config_Dumps"
```

### `maintenance-all`

One-command wrapper for full maintenance:
1) `update-all`
2) `disk-clean-safe --deep-system-clean`

Notes:
- Verifies required child scripts exist and are executable.
- Uses lock file protection against concurrent execution.

```bash
./maintenance-all
./maintenance-all --run
./maintenance-all --run --days 30
./maintenance-all --run --backup-dir "$HOME/Backups/Snapshots/Config_Dumps"
```

### `backup-skeleton`

Backs up only the folder structure of `$HOME` (no files).

```bash
./backup-skeleton
./backup-skeleton --run
./backup-skeleton --run --dest "$HOME/Backups/Snapshots" --name home-skeleton
```

### `restore-skeleton`

Recreates folder structure from a skeleton snapshot.

```bash
./restore-skeleton --from "$HOME/Backups/Snapshots/home-skeleton"
./restore-skeleton --from "$HOME/Backups/Snapshots/home-skeleton" --to "$HOME/test-restore" --run
```

### `backup-configs`

Backs up key local configuration files and a snapshot of `ops/scripts`.

Notes:
- Preserves relative config file paths under `files/`.
- Generates `SHA256SUMS.txt` for integrity verification.

```bash
./backup-configs
./backup-configs --run
./backup-configs --run --dest "$HOME/Backups/Snapshots/Config_Dumps" --name my-configs
```

### `health-check`

Quick host diagnostics (system, RAM, disk, battery, services, and common ports).

Note:
- Falls back to `grep` if `rg` is not available.

```bash
./health-check
./health-check --run
```

### `docker-clean-safe`

Safe Docker cleanup workflow.

Optional:
- `--with-volumes` adds `docker volume prune -f` (disabled by default).

```bash
./docker-clean-safe
./docker-clean-safe --run
./docker-clean-safe --run --with-volumes
```

### `disk-clean-safe`

Safe user-space disk cleanup (trash, thumbnails, old temp/cache files).

```bash
./disk-clean-safe
./disk-clean-safe --run
./disk-clean-safe --run --days 30
./disk-clean-safe --run --deep-system-clean
```

`--deep-system-clean` also runs optional system cleanup:

- `apt autoremove/autoclean/clean`
- removes disabled old snap revisions
- `flatpak uninstall --unused`
- `journalctl --vacuum-time=14d`

### `net-debug`

Quick network diagnostics (IPs, routing, DNS, pings, listening ports).

Note:
- Falls back to `grep` if `rg` is not available.

```bash
./net-debug
./net-debug --run
./net-debug --run --host github.com
```

### `install-direnv-just-k6`

Installs lightweight dev workflow tools:

- `direnv`
- `just`
- `k6` (official Debian repository)

Notes:
- Checks required commands (`sudo`, `curl`, `gpg`) before execution.
- Uses `apt-get` for automation-safe package installs.

```bash
./install-direnv-just-k6
./install-direnv-just-k6 --run
```

### `lint-scripts`

Validates script syntax (`bash -n`) for all bash scripts in this folder and runs `shellcheck` when installed.

```bash
./lint-scripts
```

## Quick Start

```bash
cd "$HOME/Workspace/ops/scripts"
```

Run any script in dry-run first, then rerun with `--run` when confirmed.

## New Tooling Usage (direnv, just, k6)

### `direnv`

Create a per-project `.envrc`:

```bash
echo 'export APP_ENV=dev' > .envrc
direnv allow
```

`direnv` will auto-load/unload variables when entering/leaving that directory.

### `just`

A `justfile` is available at `$HOME/justfile` with:

- `up` → starts your local Docker stacks
- `down` → stops them
- `logs` → tails Traefik logs

```bash
cd "$HOME"
just --list
just up
just logs
just down
```

### `k6`

Quick smoke test:

```bash
k6 run - <<'EOF'
import http from 'k6/http';
import { sleep } from 'k6';
export default function () {
  http.get('http://127.0.0.1');
  sleep(1);
}
EOF
```
