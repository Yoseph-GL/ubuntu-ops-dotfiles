> **WARNING:** This repository is my personal, highly opinionated setup. It includes hardcoded paths, environment assumptions, and custom backup routines tailored to my machine. Do **not** run these scripts blindly on your system; use them as reference and adapt carefully.

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
├── LICENSE
└── README.md
```

## Module Overview

- **setup_and_backup/**: Home-directory skeleton backup/restore flows and a personal bootstrap installer for `direnv`, `just`, and `k6`.
- **maintenance/**: System update orchestration (`apt`, `snap`, `flatpak`) plus script lint/syntax checks.
- **system/**: Host health checks, disk cleanup routines, and deeper journal/systemd log diagnostics.
- **network/**: Fast network triage (IPs, routes, DNS, pings, and listening ports).
- **docker/**: Safe Docker cleanup and container-network mapping/audit utilities.

## Quick Start & Activation

1. Clone the repository:

```bash
git clone https://github.com/Yoseph-GL/ubuntu-ops-dotfiles.git /home/joseph/Workspace/ops/scripts/ubuntu-ops-dotfiles
cd /home/joseph/Workspace/ops/scripts/ubuntu-ops-dotfiles
```

2. Make scripts executable:

```bash
chmod +x docker/* system/* network/* maintenance/* setup_and_backup/*
```

3. Export folders to your `PATH`:

For **Bash** (`~/.bashrc`) and **Zsh** (`~/.zshrc`):

```bash
export UBUNTU_OPS_DOTFILES="/home/joseph/Workspace/ops/scripts/ubuntu-ops-dotfiles"
export PATH="$UBUNTU_OPS_DOTFILES/docker:$UBUNTU_OPS_DOTFILES/system:$UBUNTU_OPS_DOTFILES/network:$UBUNTU_OPS_DOTFILES/maintenance:$UBUNTU_OPS_DOTFILES/setup_and_backup:$PATH"
```

> If you clone this repository to a different location, update `UBUNTU_OPS_DOTFILES` to match your local path.

4. Reload your shell:

```bash
source ~/.bashrc
# or
source ~/.zshrc
```

5. Verify activation:

```bash
health-check --help
maintenance-all --help
backup-skeleton --help
```

## Usage

### setup_and_backup

```bash
backup-skeleton
restore-skeleton
install-direnv-just-k6
```

### Maintenance

```bash
update-all
update-all --run
maintenance-all --run --days 21
lint-scripts --run
```

### System

```bash
health-check --run
check-logs.sh --run
disk-clean-safe
disk-clean-safe --run --days 30
```

### Network

```bash
net-debug --run
net-debug --run --host github.com
```

### Docker

```bash
docker-clean-safe
docker-clean-safe --run --with-volumes
docker-net-audit.sh --run
```

> **Environment Note:** These tools rely on a very specific local setup (for example `$HOME/Backups/Snapshots`, non-interactive `sudo`, systemd/journalctl availability, and local Docker/network conventions).
