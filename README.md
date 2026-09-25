# Bash Playground

Scratch space for small Bash utilities and experiments.

## Layout

```text
random_scripts/                 # Standalone scripts
  README.md                     # Index of scripts
  <name>.sh / <name>.md         # Script + its docs
```

## Quick start

```bash
cd random_scripts
./check_podman_image.sh localhost/container-image:local
./check_podman_stats.sh
```

Script index: **[random_scripts/README.md](random_scripts/README.md)**. Per-script docs live next to each `.sh` (e.g. [check_podman_image.md](random_scripts/check_podman_image.md), [check_podman_stats.md](random_scripts/check_podman_stats.md)).

## Requirements

- Bash
- Per-script tools (e.g. Podman for the `check_podman_*.sh` scripts)
