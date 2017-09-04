#!/usr/bin/env bash
# Rsyncs the segmentation result of kitti sequence.

function fail {
  LAST_ERR="$?"
  echo >&2 "Failed to process sequence: $1."
  echo >&2 "Please check the output above for more details."
  exit "$LAST_ERR"
}

# TODO(andrei): Cityscapify properly!

EURYALE_HOST="euryale"
#EURYALE_HOST="en02"

EUR_PROJECT_DIR="/import/euryale/projects/BARSANA.MSC.PROJECT"
#DATASET="kitti-odometry"
#DATASET="kitti"
DATASET="kitti-tracking"
REMOTE_KITTI_DIR="${EUR_PROJECT_DIR}/${DATASET}/"

if [[ "$#" -ne 1 && "$#" -ne 2 ]]; then
  echo >&2 "Usage: $0 <kitti_sequence_root> <tracking_sequence_id>"
  exit 1
fi

SEQUENCE_ROOT="$1"
SEQUENCE_ROOT="${SEQUENCE_ROOT%/}"      # Removes trailing slashes
SEQUENCE_FOLDER="${SEQUENCE_ROOT##*/}"

# Quick sanity check for KITTI folders.
if [[ "$DATASET" == "kitti" ]]; then
  if ! [[ -d "${SEQUENCE_ROOT}/image_00" ]]; then
    echo >&2 "The folder ${SEQUENCE_ROOT} does not look like a KITTI dataset folder."
    ls "${SEQUENCE_ROOT}"
    exit 2
  fi
fi

if [[ "$DATASET" == "kitti" ]]; then
  SEG_OUTPUT_SUBFOLDER=seg_image_02/mnc
elif [[ "$DATASET" == "kitti-odometry" ]]; then
  SEG_OUTPUT_SUBFOLDER=seg_image_2/mnc
elif [[ "$DATASET" == "cityscapes" ]]; then
  SEG_OUTPUT_SUBFOLDER=seg/mnc
elif [[ "$DATASET" == "kitti-tracking" ]]; then
  KT_ID="$2"
  shift
  echo "Will process 'kitti-tracking' sequence with ID #${KT_ID}."
  SEG_OUTPUT_SUBFOLDER="training/seg_image_02/$(printf '%04d' ${KT_ID})/mnc"
else
  fail "Unknown dataset name: ${DATASET}"
fi

rsync -a --info=progress2 \
  "${EURYALE_HOST}:${REMOTE_KITTI_DIR}/${SEQUENCE_FOLDER}/${SEG_OUTPUT_SUBFOLDER}/" \
  "${SEQUENCE_ROOT}/${SEG_OUTPUT_SUBFOLDER}"

echo "Fetched segmentation result from Euryale host: ${EURYALE_HOST}."

