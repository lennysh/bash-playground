#!/usr/bin/env bash
set -euo pipefail

# Check if an image tag argument was provided
if [ -z "${1:-}" ]; then
  echo "Error: Missing image name and tag."
  echo "Usage:   $0 <image_name:tag>"
  echo "Example: $0 localhost/container-image:local"
  exit 1
fi

IMAGE_TAG="$1"

# Get the target local image ID
TARGET_IMAGE_ID=$(podman image inspect -f '{{.Id}}' "$IMAGE_TAG" 2>/dev/null || true)

if [ -z "$TARGET_IMAGE_ID" ]; then
  echo "Error: Image '$IMAGE_TAG' not found in local Podman store."
  exit 1
fi

echo "=========================================================="
echo "Target Image: $IMAGE_TAG"
echo "Latest ID:   $TARGET_IMAGE_ID"
echo "=========================================================="
echo ""

MATCH_COUNT=0
MISMATCH_COUNT=0
FOUND_ANY=0

# Loop through all containers (running and stopped)
while IFS='|' read -r c_id c_name c_img_name c_pod; do
  [ -z "$c_id" ] && continue

  # Retrieve full image ID for the specific container
  c_img_id=$(podman inspect -f '{{.Image}}' "$c_id" 2>/dev/null || true)

  # Check if container was built from this image tag OR matches the image ID
  if [ "$c_img_name" = "$IMAGE_TAG" ] || [ "$c_img_id" = "$TARGET_IMAGE_ID" ]; then
    FOUND_ANY=1

    POD_INFO=""
    if [ -n "$c_pod" ]; then
      POD_INFO=" [Pod: $c_pod]"
    fi

    if [ "$c_img_id" = "$TARGET_IMAGE_ID" ]; then
      echo " [MATCH]    Container: $c_name ($c_id)$POD_INFO"
      echo "            Running ID: $c_img_id"
      MATCH_COUNT=$((MATCH_COUNT + 1))
    else
      echo " [MISMATCH] Container: $c_name ($c_id)$POD_INFO"
      echo "            Running ID: $c_img_id"
      MISMATCH_COUNT=$((MISMATCH_COUNT + 1))
    fi
    echo "----------------------------------------------------------"
  fi
done < <(podman ps -a --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.PodName}}')

if [ "$FOUND_ANY" -eq 0 ]; then
  echo "No containers found using image '$IMAGE_TAG'."
else
  echo ""
  echo "Results: $MATCH_COUNT up-to-date, $MISMATCH_COUNT outdated."
fi
