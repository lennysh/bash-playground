# check_podman_stats.sh

One-shot snapshot of CPU and memory usage for **running** Podman containers, sorted by memory % (highest first), with a totals row. Also shows each container’s image and pod (when it belongs to one).

## Requirements

- Bash (associative arrays / `mapfile` — Bash 4+)
- [Podman](https://podman.io/) (tested with 5.x)
- `column` (util-linux)

## Usage

```bash
./check_podman_stats.sh
```

No arguments. Only running containers are included (same default as `podman stats`).

## Output

| Column | Source |
|--------|--------|
| `NAME` | Container name (`podman stats`) |
| `POD` | Pod name (`podman ps`); **omitted** when no running container is in a pod |
| `IMAGE` | Image reference (`podman ps`) |
| `CPU %` | CPU percent |
| `MEM USAGE / LIMIT` | Memory used / limit |
| `MEM %` | Memory percent of limit |

Rows are sorted by `MEM %` descending. The `TOTAL` line sums CPU % and MEM % across containers and sums memory usage (normalized to MiB/GiB). The limit on the total line is the host/cgroup limit reported for the containers.

## Notes

- `podman stats` does **not** expose Image or Pod in its format template, so those columns are joined from `podman ps` by container name.
- Memory unit parsing treats Podman’s `B` / `kB` / `MB` / `GB` style strings when summing usage.
- Stopped containers are omitted; use `podman stats --all` patterns elsewhere if you need those.
