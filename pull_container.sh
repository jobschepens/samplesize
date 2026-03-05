#!/bin/bash
# Pull the standard BRMS container for this project
# Run this ON RAMSES

set -e

CONTAINER_DIR="$HOME/containers"
IMAGE_NAME="brms-workshop_working.sif"
# Use 'main' to track the latest build from the main branch
DOCKER_URL="docker://ghcr.io/jobschepens/brms-workshop:main"

echo "=========================================="
echo "Pulling Container for Simulation"
echo "=========================================="
echo "Target: $CONTAINER_DIR/$IMAGE_NAME"
echo ""

mkdir -p $CONTAINER_DIR

# Check if it exists
if [ -f "$CONTAINER_DIR/$IMAGE_NAME" ]; then
    echo "⚠️  Container already exists."
    echo "   Size: $(du -h $CONTAINER_DIR/$IMAGE_NAME | cut -f1)"
    echo "   NOTE: You MUST overwrite to get the latest version."
    read -p "   Overwrite? (y/n) [n]: " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo "   Skipping pull. Job will use OLD container."
        exit 0
    fi
    rm "$CONTAINER_DIR/$IMAGE_NAME"
fi

echo "Pulling from GitHub Container Registry (GHCR)..."
apptainer pull --dir $CONTAINER_DIR $IMAGE_NAME $DOCKER_URL

echo ""
echo "✅ Container ready at: $CONTAINER_DIR/$IMAGE_NAME"
