# Ubuntu Ops Dotfiles

Personal operations scripts for maintenance, diagnostics, Docker housekeeping,
and backup/snapshot workflows. Hardcoded paths and environment assumptions
specific to the author's machine. Review before executing.

## Structure

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

## Modules

- **setup_and_backup/**: home-directory skeleton backup/restore, bootstrap installer for `direnv`, `just`, `k6`.
- **maintenance/**: system update orchestration (`apt`, `snap`, `flatpak`), script lint/syntax checks.
- **system/**: host health checks, disk cleanup, journald/systemd log diagnostics.
- **network/**: fast network triage (IPs, routes, DNS, pings, listening ports).
- **docker/**: safe Docker cleanup, container-network mapping/audit.

## Quickstart

```bash
git clone https://github.com/Yoseph-GL/ubuntu-ops-dotfiles.git /home/joseph/Workspace/ops/scripts/ubuntu-ops-dotfiles
cd /home/joseph/Workspace/ops/scripts/ubuntu-ops-dotfiles
chmod +x docker/* system/* network/* maintenance/* setup_and_backup/*
```

Add to `~/.bashrc` or `~/.zshrc`:

```bash
export UBUNTU_OPS_DOTFILES="/home/joseph/Workspace/ops/scripts/ubuntu-ops-dotfiles"
export PATH="$UBUNTU_OPS_DOTFILES/docker:$UBUNTU_OPS_DOTFILES/system:$UBUNTU_OPS_DOTFILES/network:$UBUNTU_OPS_DOTFILES/maintenance:$UBUNTU_OPS_DOTFILES/setup_and_backup:$PATH"
```

Reload and verify:

```bash
source ~/.bashrc   # or source ~/.zshrc
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
