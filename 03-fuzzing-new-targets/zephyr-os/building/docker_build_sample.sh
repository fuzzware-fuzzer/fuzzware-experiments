#!/bin/bash
# This script is to be run within the zephyr CI docker container
# It reproduces a vulnerable sample of zephyr-OS for the given CVE

set -x
set -e

# Create zephyr workspace for the given version if needed
workspace_dir=/workdir/workspace-$ZEPHYR_VERSION
if [ ! -e "$workspace_dir" ]; then
    west init --mr=zephyr-v$ZEPHYR_VERSION $workspace_dir
    cd $workspace_dir
    west update
fi
cd /workdir/workspace-$ZEPHYR_VERSION/zephyr
export ZEPHYR_BASE=$(pwd)

# Restore git state
git reset --hard
git clean -df
git checkout "$BASE_COMMIT"
west update

# Backport fix for device binding bug
git cherry-pick 5b36a01a67dd705248496ef46999f39b43e02da9 --no-commit

# Revert the changes that fixed the issue (but keep the other fixes)
for commit in $FIX_COMMITS; do
    git revert "$commit" -n
done

# Apply base patches
for patch in ${PATCHES:-}; do
    git apply /workdir/building/patches/$patch 
done

# Build sample
cd $SAMPLE_DIR
rm -rf build
west build --pristine always -b $BOARD . -- -DSHIELD="$SHIELD" -DOVERLAY_CONFIG="$OVERLAYS" ${EXTRA_DEFINES:-}

# Copy sample to outside-visible directory
OUT_DIR="/workdir/rebuilt/CVE-$CVENUM"
rm -rf $OUT_DIR
mkdir -p $OUT_DIR
cp build/zephyr/zephyr.elf $OUT_DIR/zephyr-CVE-$CVENUM.elf
cp build/zephyr/zephyr.bin $OUT_DIR/zephyr-CVE-$CVENUM.bin
