#!/usr/bin/env bash

# Directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#SBATCH_FLAGS="--nodelist=node03"
SBATCH_FLAGS=""

# Enable module support.
source /etc/profile || {
  echo >&2 "Could not source /etc/profile for setting up modules support."
  exit 1
}

echo "Sourced /etc/profile. Submitting job..."

mkdir -p ~/experiments/"$(date +'%Y-%m-%d')" && cd $_ && \
  echo "In $(pwd). Calling sbatch..." && \
  sbatch ${SBATCH_FLAGS} ${SCRIPT_DIR}/mnc-demo-batch.sh "$@"
