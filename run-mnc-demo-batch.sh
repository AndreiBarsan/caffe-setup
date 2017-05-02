#!/usr/bin/env bash

# Directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Enable module support.
#source /etc/profile.d/11-modules.sh #>/dev/null 2>&1
source /etc/profile

mkdir -p ~/experiments/"$(date +'%Y-%m-%d')" && cd $_ && \
  sbatch ${SCRIPT_DIR}/mnc-demo-batch.sh "$@"
