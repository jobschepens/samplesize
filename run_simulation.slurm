#!/bin/bash -l
#SBATCH --job-name=sim_random
#SBATCH --output=sim_random_%j.out
#SBATCH --error=sim_random_%j.err
#SBATCH --time=08:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64gb
#SBATCH --account=ag-reiter
#SBATCH --partition=smp


# ==============================================================================
# RAMSES SLURM Script for Simulation
# ==============================================================================

# 1. Config
SIMULATION_PROFILE=ramses
export SIMULATION_PROFILE

CONTAINER="$HOME/containers/brms-workshop_working.sif"
PROJECT_DIR="$HOME/temp/random"
SCRIPT_TO_RUN="scripts/simulation/run_simulation_scenarios.R"

# Verify container exists
if [ ! -f "$CONTAINER" ]; then
    echo "❌ Container not found: $CONTAINER"
    echo "   Run 'bash pull_container.sh' first."
    exit 1
fi

# 2. Setup Work Directory in /scratch
# /scratch is much faster than /home for I/O and avoids quota issues
WORKDIR="/scratch/${USER}/${SLURM_JOB_ID}"
echo "Setting up workdir: $WORKDIR"
mkdir -p $WORKDIR

# 3. Copy project files to /scratch
echo "Copying files to scratch..."
# Copy everything from project dir to scratch
cp -r $PROJECT_DIR/* $WORKDIR/

# 4. Run Analysis
cd $WORKDIR
echo "Starting analysis in $(pwd)..."
echo "------------------------------------------------------------------------"

echo "Debug: Contents of workspace mapping:"
ls -LR .

echo "Debug: Checking container version..."
apptainer exec $CONTAINER R --version

echo "Debug: Executing Rscript..."
apptainer exec \
  --bind $WORKDIR:/workspace \
  --bind /scratch/$USER:/scratch \
  --pwd /workspace \
  $CONTAINER \
  Rscript $SCRIPT_TO_RUN $SIMULATION_PROFILE

echo "Debug: Exit code of Rscript: $?"

echo "------------------------------------------------------------------------"
echo "Analysis finished."

# 5. Save Results
echo "Copying results back to home..."
# R script saves to data/csv/ and data/rds/ relative to /workspace (= $WORKDIR)
mkdir -p $PROJECT_DIR/data/csv $PROJECT_DIR/data/rds
if [ -d "$WORKDIR/data/csv" ]; then
    cp -v $WORKDIR/data/csv/*.csv $PROJECT_DIR/data/csv/ 2>/dev/null || echo "No CSV files found"
fi
if [ -d "$WORKDIR/data/rds" ]; then
    cp -v $WORKDIR/data/rds/*.rds $PROJECT_DIR/data/rds/ 2>/dev/null || echo "No RDS files found"
fi
# 6. Cleanup
echo "Cleaning up scratch..."
cd /
rm -rf $WORKDIR

echo "✅ Job Completed."
