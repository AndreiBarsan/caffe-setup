#!/usr/bin/env bash

# Directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Enable module support.
source /etc/profile || {
  echo >&2 "Could not source /etc/profile for setting up modules support."
  exit 1
}

echo "Sourced /etc/profile. Submitting job..."

mkdir -p ~/experiments/"$(date +'%Y-%m-%d')" && cd $_ && \
  echo "In $(pwd). Calling sbatch..." && \
  sbatch ${SCRIPT_DIR}/mnc-demo-batch.sh "$@"
