#!/bin/bash
set -e

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
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Building Docker image..."
    docker build -f build-yocto.Dockerfile -t "$IMAGE_NAME" .
else
    echo "Docker image '$IMAGE_NAME' already exists, skipping build..."
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create a temporary container to extract files
echo ""
echo "Extracting built images using docker cp..."
CONTAINER_ID=$(docker create "$IMAGE_NAME")

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
echo "docker run -it --rm \\"
echo "  -v '$OUTPUT_DIR:/images' \\"
echo "  fvp-corstone-1000 \\"
echo "  /opt/corstone-1000/models/Linux64_armv8l_GCC-9.3/FVP_Corstone-1000 \\"
echo "  -C diagnostics=4 \\"
echo "  -C se.trustedBootROMloader.fname='/images/bl1.bin' \\"
echo "  -C se.trustedSRAM_config=6 \\"
echo "  -C se.BootROM_config='3' \\"
echo "  --data board.flash0='/images/corstone1000-image-corstone1000-fvp.wic.nopt@0x68050000' \\"
echo "  -C board.xnvm_size=64 \\"
echo "  -C board.smsc_91c111.enabled=1 \\"
echo "  -C board.hostbridge.userNetworking=true \\"
echo "  -C board.se_flash_size=8192"