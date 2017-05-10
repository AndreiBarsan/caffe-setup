#!/usr/bin/env bash
# Processes a kitti sequence on Euryale, ETHZ IVC's mini GPU cluster.
# Assumes MNC is already set up on Euryale.

set -u
set -o pipefail

function fail {
  LAST_ERR="$?"
  echo >&2 "Failed to process sequence: $1."
  echo >&2 "Please check the output above for more details."
  exit "$LAST_ERR"
}


MNC_EURYALE_PATH="work/MNC"
EURYALE_HOST="euryale"
EUR_PROJECT_DIR="/import/euryale/projects/BARSANA.MSC.PROJECT"

# The dataset the sequence we're processing is part of.
# Currently supported are 'kitti', 'kitti-odometry' and 'cityscapes'.
#DATASET="kitti"
DATASET="kitti-odometry"

REMOTE_DIR="${EUR_PROJECT_DIR}/${DATASET}/"

if [[ "$#" -lt 1 ]]; then
  echo >&2 "Usage: $0 <video_sequence_root> <job args>"
  exit 1
fi

SEQUENCE_ROOT="$1"
shift
SEQUENCE_ROOT="${SEQUENCE_ROOT%/}"      # Removes trailing slashes
SEQUENCE_FOLDER="${SEQUENCE_ROOT##*/}"

if [[ "${DATASET}" == "kitti" ]]; then
  # Quick sanity check for KITTI folders.
  if ! [[ -d "${SEQUENCE_ROOT}/image_00" ]]; then
    echo >&2 "The folder ${SEQUENCE_ROOT} does not look like a KITTI dataset folder."
    ls "${SEQUENCE_ROOT}"
    exit 2
  fi
fi


echo "Will use ${DATASET} sequence from folder: ${SEQUENCE_ROOT}"
echo "${DATASET} folder name: ${SEQUENCE_FOLDER}"

# This is where we will be putting our segmentation result.
if [[ "$DATASET" == "kitti" ]]; then
  INPUT_SUBFOLDER="image_02/data"
  SEG_OUTPUT_SUBFOLDER=seg_image_02/mnc
elif [[ "$DATASET" == "kitti-odometry" ]]; then
  INPUT_SUBFOLDER="image_2"
  SEG_OUTPUT_SUBFOLDER=seg_image_2/mnc
elif [[ "$DATASET" == "cityscapes" ]]; then
  INPUT_SUBFOLDER=""
  SEG_OUTPUT_SUBFOLDER=seg/mnc
else
  fail "Unknown dataset name: ${DATASET}"
fi

# This depends on the structure of the dataset
mkdir -p "${SEQUENCE_ROOT}/${SEG_OUTPUT_SUBFOLDER}"

# Sync data to Euryale folder
ssh "$EURYALE_HOST" mkdir -p "$REMOTE_DIR"
rsync -a --info=progress2 "${SEQUENCE_ROOT}" "${EURYALE_HOST}:${REMOTE_DIR}" || {
  fail "Could not rsync data."
}

# Sync our setup code (but NOT the actual MNC stuff; that's assumed to already
# be available). See './setup-mnc.sh' for more information.
# TODO(andrei): Don't sync the 'git' directory.
ssh "$EURYALE_HOST" mkdir -p work/setup
rsync -a "$(pwd -P)/" "${EURYALE_HOST}:work/setup" || {
  fail "Could not rsync Bash helper scripts."
}

# Sync the Python tools part of the MNC code.
rsync -a $(pwd -P)/../MNC/tools/*.py "${EURYALE_HOST}:work/MNC/tools/" || {
  fail "Could not rsync Python tools (tools)."
}
rsync -a $(pwd -P)/../MNC/lib/**/*.py "${EURYALE_HOST}:work/MNC/tools/" || {
  fail "Could not rsync Python tools (lib)."
}

echo "rsynced data and code OK."

ssh "$EURYALE_HOST" '~/work/setup/run-mnc-demo-batch.sh' \
  --input "${REMOTE_DIR}/${SEQUENCE_FOLDER}/${INPUT_SUBFOLDER}" \
  --output "${REMOTE_DIR}/${SEQUENCE_FOLDER}/${SEG_OUTPUT_SUBFOLDER}" "$@" || {
  fail "Could not kick off batch job."
}

# This can be used for debugging.
#ssh "$EURYALE_HOST" -Y '~/work/setup/run-mnc-demo.sh' \
  #--input '~/work/MNC/data/demo' --output '~/work/MNC/data/demo/output' "$@"

echo "Batch job launched OK."

