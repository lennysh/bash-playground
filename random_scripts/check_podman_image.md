# check_podman_image.sh

Compares containers that reference a given image tag against the **current** local image ID for that tag. Useful after rebuilding an image to see which containers are still on an older ID.

## Requirements

- Bash
- [Podman](https://podman.io/) (tested with 5.x)

## Usage

```bash
./check_podman_image.sh <image_name:tag>
```

**Example:**

```bash
./check_podman_image.sh localhost/container-image:local
```

## Output

| Label | Meaning |
|-------|---------|
| `[MATCH]` | Container image ID equals the current local image ID |
| `[MISMATCH]` | Container still uses an older image ID for that tag |
| (none) | No containers (running or stopped) use that tag / ID |

Also prints a short summary: how many are up to date vs outdated.

## Notes

- Looks at all containers (`podman ps -a`), not only running ones.
- Image name matching is exact string equality against the tag you pass (e.g. `localhost/foo:local`).
- Presence of a pod name is shown when the container belongs to a pod.
