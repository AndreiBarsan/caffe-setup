#!/usr/bin/env bash
# Rsyncs the segmentation result of kitti sequence.

function fail {
  LAST_ERR="$?"
  echo >&2 "Failed to process sequence: $1."
  echo >&2 "Please check the output above for more details."
  exit "$LAST_ERR"
}


EURYALE_HOST="euryale"
#EURYALE_HOST="en02"

EUR_PROJECT_DIR="/import/euryale/projects/BARSANA.MSC.PROJECT"
REMOTE_KITTI_DIR="${EUR_PROJECT_DIR}/kitti/"

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

# This is where we will be putting our segmentation result.
mkdir -p "${KITTI_ROOT}/seg_image_02/mnc"

rsync -a "${EURYALE_HOST}:${REMOTE_KITTI_DIR}/${KITTI_FOLDER}/seg_image_02/" \
  "${KITTI_ROOT}/seg_image_02"

echo "Fetched segmentation result from Euryale host: ${EURYALE_HOST}."

