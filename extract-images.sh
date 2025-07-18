#!/bin/bash
set -euo pipefail

# Script to build Corstone-1000 images and extract them to host
# This script orchestrates the Docker build and extraction process

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/corstone1000-images"
IMAGE_NAME="corstone1000-builder"

echo "Building Corstone-1000 images using Docker..."
echo "This will take a significant amount of time (30-60 minutes or more)"
echo "Output will be saved to: $OUTPUT_DIR"
echo ""

# Build the Docker image (if not already built)
if ! docker build -f build-yocto.Dockerfile -t "$IMAGE_NAME" .; then
    echo "Error: Failed to build Docker image" >&2
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a temporary container to extract files
echo ""
echo "Extracting built images using docker cp..."
CONTAINER_ID=$(docker create -q "$IMAGE_NAME")

# Validate the deployment directory exists in the container
if ! docker exec "$CONTAINER_ID" test -d "$DEPLOY_DIR"; then
    echo "Error: Deployment directory $DEPLOY_DIR not found in container" >&2
    docker rm "$CONTAINER_ID" >/dev/null
    exit 1
fi

# Define the source directory in the container
DEPLOY_DIR="/workspace/build/tmp/deploy/images/corstone1000-fvp"

# List of files to extract
FILES=(
    "bl1.bin"
    "es_flashfw.bin"
    "corstone1000-image-corstone1000-fvp.wic.nopt"
    "corstone1000-flash-firmware-image-corstone1000-fvp.wic"
    "cc312_otp.bin"
)

# Extract each file if it exists
for file in "${FILES[@]}"; do
    if docker cp "$CONTAINER_ID:$DEPLOY_DIR/$file" "$OUTPUT_DIR/" 2>/dev/null; then
        echo "✓ Extracted $file"
    else
        echo "✗ $file not found, skipping"
    fi
done

# Clean up the temporary container
docker rm "$CONTAINER_ID" >/dev/null

echo ""
echo "Build complete! Images are available in: $OUTPUT_DIR"
echo ""
echo "Files extracted:"
ls -la "$OUTPUT_DIR/"

echo ""
echo "To run the FVP with these images, use:"
cat << EOF
docker run -it --rm \\
  -v '$OUTPUT_DIR:/images' \\
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
