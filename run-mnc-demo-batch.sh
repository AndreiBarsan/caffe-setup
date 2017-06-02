#!/usr/bin/env bash

# Directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#SBATCH_FLAGS="--nodelist=node03"
#SBATCH_FLAGS="--jobid=2294"
SBATCH_FLAGS=""
#export SLURM_JOB_ID=2302
#echo "HARDCODED SLURM_JOB_ID: $SLURM_JOB_ID"

# Enable module support.
source /etc/profile || {
  echo >&2 "Could not source /etc/profile for setting up modules support."
  exit 1
}


echo "Sourced /etc/profile. Submitting job..."

mkdir -p ~/experiments/"$(date +'%Y-%m-%d')" && cd $_ && \
echo "In $(pwd). Calling sbatch..." && \
  sbatch ${SBATCH_FLAGS} ${SCRIPT_DIR}/mnc-demo-batch.sh "$@"

# For debugging
#mkdir -p ~/experiments/"$(date +'%Y-%m-%d')" && cd $_ && \
  #echo "In $(pwd). Calling srun with fixed SLURM_JOB_ID ($SLURM_JOB_ID)..." && \
  #srun ${SBATCH_FLAGS} ${SCRIPT_DIR}/mnc-demo-batch.sh "$@"
