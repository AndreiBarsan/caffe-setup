#!/usr/bin/env bash

# Directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#SBATCH_FLAGS="--nodelist=node03"
#SBATCH_FLAGS=""
SBATCH_FLAGS="--jobid=5154"
export SLURM_JOB_ID=5154
echo "Warning: HARDCODED SLURM_JOB_ID: [${SLURM_JOB_ID}]"

# Enable module support.
source /etc/profile || {
  echo >&2 "Could not source /etc/profile for setting up modules support."
  exit 1
}
echo "Sourced /etc/profile. Submitting job..."

mkdir -p ~/experiments/"$(date +'%Y-%m-%d')" && cd $_ && \
echo "In $(pwd). Calling sbatch... with flags [${SBATCH_FLAGS}] for script dir [${SCRIPT_DIR}] " && \
  sbatch ${SBATCH_FLAGS} ${SCRIPT_DIR}/mnc-demo-batch.sh "$@" || echo "sbatch failed"

# For debugging
#mkdir -p ~/experiments/"$(date +'%Y-%m-%d')" && cd $_ && \
  #echo "In $(pwd). Calling srun with fixed SLURM_JOB_ID ($SLURM_JOB_ID)..." && \
  #srun ${SBATCH_FLAGS} ${SCRIPT_DIR}/mnc-demo-batch.sh "$@"
