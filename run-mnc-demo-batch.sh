#!/usr/bin/env bash

# Directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Enable module support.
#source /etc/profile.d/11-modules.sh #>/dev/null 2>&1
source /etc/profile

echo "Sourced /etc/profile OK, and sbatch-ing actual job."

mkdir -p ~/experiments/"$(date +'%Y-%m-%d')" && cd $_ && \
  echo "In $(pwd). Calling sbatch..." && \
  sbatch ${SCRIPT_DIR}/mnc-demo-batch.sh "$@"
