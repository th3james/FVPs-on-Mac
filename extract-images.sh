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

# Build the Docker image using BuildKit for cache mount support
echo "Building with Docker BuildKit for optimized caching..."
if ! DOCKER_BUILDKIT=1 docker build -f build-yocto.Dockerfile -t "$IMAGE_NAME" .; then
    echo "Error: Failed to build Docker image" >&2
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Define the source directory in the container
DEPLOY_DIR="/workspace/build/tmp/deploy/images/corstone1000-fvp"

# Create a temporary container to extract files
echo ""
echo "Extracting built images using docker cp..."
CONTAINER_ID=$(docker create -q "$IMAGE_NAME")

# Extract all files from the deploy directory and create symlinks locally
echo "Extracting all files from deploy directory..."
if docker cp "$CONTAINER_ID:$DEPLOY_DIR/." "$OUTPUT_DIR/" 2>/dev/null; then
    echo "✓ Extracted all files from deploy directory"
    
    # Create a simplified symlink for the main wic file if it doesn't exist
    cd "$OUTPUT_DIR"
    if [ ! -f "corstone1000-esp-image-corstone1000-fvp.wic" ] && ls corstone1000-esp-image-corstone1000-fvp-*.wic 1> /dev/null 2>&1; then
        ln -sf corstone1000-esp-image-corstone1000-fvp-*.wic corstone1000-esp-image-corstone1000-fvp.wic
        echo "✓ Created symlink for main wic file"
    fi
    cd - > /dev/null
else
    echo "✗ Failed to extract files from deploy directory"
fi

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
  --data board.flash0='/images/corstone1000-esp-image-corstone1000-fvp.wic@0x68050000' \\
  -C board.xnvm_size=64 \\
  -C board.smsc_91c111.enabled=1 \\
  -C board.hostbridge.userNetworking=true \\
  -C board.se_flash_size=8192
EOF
