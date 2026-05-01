# Ops Scripts

Coleccion de scripts de operacion para mantenimiento, snapshots y diagnostico local.

## Manual-Safe Policy

Todos los scripts siguen un modelo manual-safe estricto:

- Sin flags: siempre `dry-run`.
- Ejecucion real: solo con `--run`.
- Tolerancia cero a typos del flag de ejecucion (`-run`, `/run`, etc.): abortan con error y salida `1`.
- Se usa `set -euo pipefail` y validaciones de dependencias.
- Todos los scripts anclan su contexto con `SCRIPT_DIR`.

## Backup Paths Policy

Las rutas de backups se restringen a:

- `$HOME/Backups/Snapshots`
- `$HOME/Backups/Snapshots/Config_Dumps`

Los scripts crean de forma segura los directorios requeridos con `mkdir -p`.

## Maintenance and Cleanup

### `update-all`

Actualiza paquetes (`apt`, `snap`, `flatpak`) y genera snapshots de estado.

```bash
./update-all
./update-all --run
./update-all --run --backup-dir "$HOME/Backups/Snapshots/Config_Dumps"
```

### `maintenance-all`

Orquesta:
1. `update-all`
2. `disk-clean-safe --deep-system-clean`

```bash
./maintenance-all
./maintenance-all --run
./maintenance-all --run --days 30
./maintenance-all --run --backup-dir "$HOME/Backups/Snapshots"
```

### `disk-clean-safe`

Limpieza segura de basura de usuario, cache y temporales antiguos.

```bash
./disk-clean-safe
./disk-clean-safe --run
./disk-clean-safe --run --days 30
./disk-clean-safe --run --deep-system-clean
```

### `docker-clean-safe`

Limpieza segura de artefactos Docker no utilizados.

```bash
./docker-clean-safe
./docker-clean-safe --run
./docker-clean-safe --run --with-volumes
```

## Backups and Snapshots

### `backup-configs`

Respalda archivos de configuracion clave y snapshot del directorio actual de scripts.

```bash
./backup-configs
./backup-configs --run
./backup-configs --run --dest "$HOME/Backups/Snapshots/Config_Dumps" --name my-configs
```

### `backup-skeleton`

Guarda solo estructura de directorios de `$HOME` (sin archivos).

```bash
./backup-skeleton
./backup-skeleton --run
./backup-skeleton --run --dest "$HOME/Backups/Snapshots" --name home-skeleton
```

### `restore-skeleton`

Restaura estructura de directorios desde un snapshot ubicado dentro de `$HOME/Backups/Snapshots`.

```bash
./restore-skeleton --from "$HOME/Backups/Snapshots/home-skeleton"
./restore-skeleton --from "$HOME/Backups/Snapshots/home-skeleton" --to "$HOME/test-restore" --run
```

## Diagnostics

### `health-check`

Diagnostico rapido de host (sistema, memoria, disco, servicios y puertos comunes).

```bash
./health-check
./health-check --run
```

### `net-debug`

Diagnostico de red (IPs, ruta por defecto, DNS, pings y puertos).

```bash
./net-debug
./net-debug --run
./net-debug --run --host github.com
```

### `check-logs.sh`

Diagnostico extendido de logs y estado del sistema.

```bash
./check-logs.sh
./check-logs.sh --run
```

### `docker-net-audit.sh`

Auditoria de mapeo de red Docker (veth/contenedor/bridge) y redes sin contenedores activos.

```bash
./docker-net-audit.sh
./docker-net-audit.sh --run
```

## Tooling

### `install-direnv-just-k6`

Configura repositorio oficial de k6 e instala `direnv`, `just` y `k6`.

```bash
./install-direnv-just-k6
./install-direnv-just-k6 --run
```

### `lint-scripts`

Valida sintaxis (`bash -n`) y ejecuta `shellcheck` si esta instalado.

```bash
./lint-scripts
./lint-scripts --run
```

## Quick Start

```bash
cd "$HOME/Workspace/ops/scripts"
```
