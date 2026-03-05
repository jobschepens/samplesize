#!/bin/bash
# Deploy 'temp/random' project to RAMSES
# Usage: bash deploy_to_ramses.sh

set -e

RAMSES_USER="jschepen"
RAMSES_HOST="ramses1.itcc.uni-koeln.de"
REMOTE_DIR="~/temp/random"

echo "=========================================="
echo "Deploying to RAMSES: $REMOTE_DIR"
echo "=========================================="

# Create remote directory structure
echo "Step 1: Creating directories on RAMSES..."
ssh ${RAMSES_USER}@${RAMSES_HOST} "mkdir -p $REMOTE_DIR/results $REMOTE_DIR/scripts"

# Sync files
echo "Step 2: Syncing files..."
# We use rsync to copy the current directory content to the remote directory
# --exclude='.git' to avoid big history files
# --exclude='results' to avoid re-uploading large results if they exist locally
# --exclude='*.Rproj' not needed on cluster
rsync -avz \
  --exclude='.git' \
  --exclude='results' \
  --exclude='*.Rproj' \
  --exclude='.DS_Store' \
  ./ \
  ${RAMSES_USER}@${RAMSES_HOST}:${REMOTE_DIR}/

echo ""
echo "=========================================="
echo "✅ Deployment complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. SSH to Ramses: ssh ${RAMSES_USER}@${RAMSES_HOST}"
echo "2. Go to folder:  cd ${REMOTE_DIR}"
echo "3. Pull container: bash pull_container.sh (only first time)"
echo "4. Submit job:    sbatch run_simulation.slurm"
echo ""
