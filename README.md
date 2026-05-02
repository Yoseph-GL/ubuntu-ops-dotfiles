> **WARNING:** This repository contains my highly opinionated, custom personal setup. It includes hardcoded paths, specific configurations, and custom backup routines tailored strictly to my environment. Do NOT run these scripts blindly on your machine. Use for reference at your own risk.

# Ubuntu Ops Dotfiles

Personal operations scripts for maintenance, diagnostics, Docker housekeeping, and backup/snapshot workflows.

## Directory Tree

```text
.
├── docker/
│   ├── docker-clean-safe
│   └── docker-net-audit.sh
├── maintenance/
│   ├── lint-scripts
│   ├── maintenance-all
│   └── update-all
├── network/
│   └── net-debug
├── setup_and_backup/
│   ├── backup-skeleton
│   ├── install-direnv-just-k6
│   └── restore-skeleton
├── system/
│   ├── check-logs.sh
│   ├── disk-clean-safe
│   └── health-check
└── README.md
```

## Module Overview

- **setup_and_backup/**: Home directory skeleton backup/restore flows and a personal bootstrap installer for `direnv`, `just`, and `k6`.
- **maintenance/**: System update orchestration (`apt`, `snap`, `flatpak`) plus script lint/syntax checks.
- **system/**: Host health checks, disk cleanup routines, and deeper journal/systemd log diagnostics.
- **network/**: Fast network triage (IPs, routes, DNS, pings, and listening ports).
- **docker/**: Safe Docker cleanup and container-network mapping/audit utilities.

> **Environment Note:** These tools rely on a very specific local setup (for example `$HOME/Backups/Snapshots`, non-interactive `sudo`, systemd/journalctl availability, and local Docker/network conventions).
