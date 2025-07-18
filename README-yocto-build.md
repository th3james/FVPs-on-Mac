# Corstone-1000 Yocto Build Guide

This guide explains how to build Corstone-1000 Linux images using the provided Docker build system.

## Quick Start

1. **Build the images:**
   ```bash
   ./extract-images.sh
   ```

2. **Run the FVP with built images:**
   ```bash
   docker run -it --rm \
     -v $(pwd)/corstone1000-images:/images \
     fvp-corstone-1000 \
     /opt/corstone-1000/models/Linux64_armv8l_GCC-9.3/FVP_Corstone-1000 \
     -C diagnostics=4 \
     -C se.trustedBootROMloader.fname='/images/bl1.bin' \
     -C se.trustedSRAM_config=6 \
     -C se.BootROM_config='3' \
     --data board.flash0='/images/corstone1000-image-corstone1000-fvp.wic.nopt@0x68050000' \
     -C board.xnvm_size=64 \
     -C board.smsc_91c111.enabled=1 \
     -C board.hostbridge.userNetworking=true \
     -C board.se_flash_size=8192
   ```

## What Gets Built

The build process creates several important files:

- **`bl1.bin`** - Secure Enclave ROM firmware (bootloader)
- **`es_flashfw.bin`** - External System Processor firmware
- **`corstone1000-image-corstone1000-fvp.wic.nopt`** - Main Linux disk image
- **`corstone1000-flash-firmware-image-corstone1000-fvp.wic`** - Flash firmware image
- **`cc312_otp.bin`** - Crypto configuration (if generated)

## Build Requirements

- **Docker** with sufficient resources:
  - At least 8GB RAM allocated to Docker
  - At least 50GB disk space
  - Fast internet connection for downloading dependencies

## Build Process Details

### 1. Build Docker Image
```bash
docker build -f build-yocto.Dockerfile -t corstone1000-builder .
```

### 2. Extract Images Manually
```bash
mkdir -p corstone1000-images
docker run --rm \
  -v $(pwd)/corstone1000-images:/output \
  corstone1000-builder
```

### 3. Manual Build Steps (if needed)
If you want to run the build manually:

```bash
# Run interactive shell in build container
docker run -it --rm \
  -v $(pwd)/corstone1000-images:/output \
  corstone1000-builder bash

# Inside container:
cd /workspace
kas build meta-arm/kas/corstone1000-fvp.yml:meta-arm/ci/debug.yml
./extract-images.sh
```

## Build Time

- **First build**: 30-90 minutes depending on your system
- **Subsequent builds**: Faster due to Docker layer caching
- **Network dependent**: Initial download of sources and dependencies

## Troubleshooting

### Build Fails with "No space left on device"
- Increase Docker disk space allocation
- Clean up unused Docker images: `docker system prune -a`

### Build Fails with Memory Issues
- Increase Docker memory allocation to at least 8GB
- Close other applications during build

### Git Errors
The build sets up git configuration automatically, but if you see git errors:
```bash
git config --global user.email "your.email@example.com"
git config --global user.name "Your Name"
```

### Permission Issues
The Dockerfile creates a non-root user for the build process to avoid Yocto permission issues.

## File Locations

After a successful build:
- **Host**: `./corstone1000-images/` (extracted images)
- **Container**: `/workspace/build/tmp/deploy/images/corstone1000-fvp/` (full build)

## What's Different from Pre-built Images

This build creates:
- A complete Linux system based on Yocto/Poky
- BusyBox utilities
- musl libc
- Approximately 5MB total size
- Optimized for embedded/IoT use cases

## Next Steps

Once you have the images built, you can:
1. Run the basic FVP command above
2. Modify the FVP parameters for your specific needs
3. Mount additional files into the Docker container
4. Set up networking between host and FVP
5. Connect debuggers to the running FVP

## Additional Resources

- [Corstone-1000 Official Documentation](https://corstone1000.docs.arm.com/)
- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [meta-arm Repository](https://git.yoctoproject.org/meta-arm/)