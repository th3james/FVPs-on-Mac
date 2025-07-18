#!/bin/bash
set -euo pipefail

# Script to build Corstone-1000 images on remote Linux host and copy back
REMOTE_HOST="shared-linux-workstation"
REMOTE_DIR="/data_sdb/th3james-src/FVP-Builder"
LOCAL_DIR="./corstone1000-images"

echo "Building Corstone-1000 images on remote host: $REMOTE_HOST"
echo ""

# First, sync the build files to remote host
echo "Syncing build files to remote host..."
./scripts/copy-to-shared-linux.sh

# Run the build on remote host
echo ""
echo "Running build on remote host..."
ssh -q "$REMOTE_HOST" << EOF
cd "$REMOTE_DIR"
echo "Starting build process..."
./extract-images.sh
echo "Build completed!"
EOF

# Create local output directory
mkdir -p "$LOCAL_DIR"

# Copy the extracted images back to local machine
echo ""
echo "Copying built images back to local machine..."
rsync -av --delete "$REMOTE_HOST:$REMOTE_DIR/corstone1000-images/" "$LOCAL_DIR/"

echo ""
echo "Build complete! Images are available locally in: $LOCAL_DIR"
echo ""
echo "Files extracted:"
ls -la "$LOCAL_DIR/"

echo ""
echo "To run the FVP with these images, use:"
cat << EOF
docker run -it --rm \\
  -v '$LOCAL_DIR:/images' \\
  fvp-corstone-1000 \\
  /opt/corstone-1000/models/Linux64_armv8l_GCC-9.3/FVP_Corstone-1000 \\
  -C diagnostics=4 \\
  -C se.trustedBootROMloader.fname='/images/bl1.bin' \\
  -C se.trustedSRAM_config=6 \\
  -C se.BootROM_config='3' \\
  --data board.flash0='/images/corstone1000-image-corstone1000-fvp.wic.nopt@0x68050000' \\
  -C board.xnvm_size=64 \\
  -C board.smsc_91c111.enabled=1 \\
  -C board.hostbridge.userNetworking=true \\
  -C board.se_flash_size=8192
EOF
