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

# Build the Docker image
echo "Building Docker image..."
docker build -f build-yocto.Dockerfile -t "$IMAGE_NAME" .

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run the container to extract images
echo ""
echo "Extracting built images..."
docker run --rm \
    -v "$OUTPUT_DIR:/output" \
    "$IMAGE_NAME"

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