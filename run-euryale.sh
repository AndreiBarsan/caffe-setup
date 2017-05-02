#!/usr/bin/env bash
# Processes a kitti sequence on Euryale, ETHZ IVC's mini GPU cluster.
# Assumes MNC is already set up on Euryale.

function fail {
  LAST_ERR="$?"
  echo >&2 "Failed to process sequence: $1."
  echo >&2 "Please check the output above for more details."
  exit "$LAST_ERR"
}


MNC_EURYALE_PATH="work/MNC"
EURYALE_HOST="euryale"
#EURYALE_HOST="en02"

EUR_PROJECT_DIR="/import/euryale/projects/BARSANA.MSC.PROJECT"
REMOTE_KITTI_DIR="${EUR_PROJECT_DIR}/kitti/"

# TODO Arg should be a kitti dir.

if [[ "$#" -ne 1 ]]; then
  echo >&2 "Usage: $0 <kitti_sequence_root>"
  exit 1
fi

KITTI_ROOT="$1"
KITTI_ROOT="${KITTI_ROOT%/}"      # Removes trailing slashes
KITTI_FOLDER="${KITTI_ROOT##*/}"

# Quick and dirty sanity check.
if ! [[ -d "${KITTI_ROOT}/image_00" ]]; then
  echo >&2 "The folder ${KITTI_ROOT} does not look like a KITTI dataset folder."
  ls "${KITTI_ROOT}"
  exit 2
fi

echo "Will use Kitti sequence from folder: ${KITTI_ROOT}"
echo "Kitti folder name: ${KITTI_FOLDER}"

# This is where we will be putting our segmentation result.
mkdir -p "${KITTI_ROOT}/seg_image_02/mnc"

# Sync data to Euryale folder
ssh "$EURYALE_HOST" mkdir -p "$REMOTE_KITTI_DIR"
rsync -a "${KITTI_ROOT}" "${EURYALE_HOST}:${REMOTE_KITTI_DIR}" || {
  fail "Could not rsync KITTI data."
}

# Sync our setup code (but NOT the actual MNC stuff; that's assumed to already
# be available). See './setup-mnc.sh' for more information.
# TODO(andrei): Don't sync the 'git' directory.
ssh "$EURYALE_HOST" mkdir -p work/setup
rsync -a "$(pwd -P)/" "${EURYALE_HOST}:work/setup" || {
  fail "Could not rsync code."
}

echo "rsynced data and code OK."

ssh "$EURYALE_HOST" '~/work/setup/run-mnc-demo-batch.sh' \
  --input "${REMOTE_KITTI_DIR}/${KITTI_FOLDER}/image_02/data" \
  --output "${REMOTE_KITTI_DIR}/${KITTI_FOLDER}/seg_image_02/mnc" || {
  fail "Could not kick off batch job."
}

echo "Batch job launched OK."

# TODO(andrei): Job to fetch stuff back. Print copypasta-friendly code here, or
# just srun the tool since we're always in tmux anyway.

#rsync -a "${EURYALE_HOST}:${REMOTE_KITTI_DIR}/${KITTI_FOLDER}/seg_image_02/" \
  #"${KITTI_ROOT}/seg_image_02"

