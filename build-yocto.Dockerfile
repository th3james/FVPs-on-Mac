# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install Yocto build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    chrpath \
    cpio \
    debianutils \
    diffstat \
    file \
    gawk \
    gcc \
    git \
    git-lfs \
    iputils-ping \
    libegl1-mesa \
    libsdl1.2-dev \
    liblz4-tool \
    make \
    python3 \
    python3-pip \
    python3-pexpect \
    python3-git \
    python3-jinja2 \
    python3-subunit \
    socat \
    texinfo \
    unzip \
    wget \
    xz-utils \
    zstd \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set up locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install kas (Yocto build tool)
RUN pip3 install kas

# Create build user (Yocto doesn't like running as root)
RUN useradd -m -s /bin/bash builder && \
    mkdir -p /workspace && \
    chown builder:builder /workspace

USER builder
WORKDIR /workspace

# Clone meta-arm repository
RUN git clone https://git.yoctoproject.org/git/meta-arm -b CORSTONE1000-2024.06

# Set up git config (required for Yocto)
RUN git config --global user.email "builder@example.com" && \
    git config --global user.name "Builder"

# Environment variable to accept FVP EULA
ENV FVP_CORSTONE1000_EULA_ACCEPT=True
ENV ARM_FVP_EULA_ACCEPT=1

# Build the Corstone-1000 FVP images
RUN kas build meta-arm/kas/corstone1000-fvp.yml:meta-arm/ci/debug.yml

# Create extraction script
RUN echo '#!/bin/bash' > /workspace/extract-images.sh && \
    echo 'set -e' >> /workspace/extract-images.sh && \
    echo '' >> /workspace/extract-images.sh && \
    echo 'DEPLOY_DIR="/workspace/build/tmp/deploy/images/corstone1000-fvp"' >> /workspace/extract-images.sh && \
    echo 'OUTPUT_DIR="/output"' >> /workspace/extract-images.sh && \
    echo '' >> /workspace/extract-images.sh && \
    echo 'echo "Extracting Corstone-1000 build artifacts..."' >> /workspace/extract-images.sh && \
    echo '' >> /workspace/extract-images.sh && \
    echo 'mkdir -p "$OUTPUT_DIR"' >> /workspace/extract-images.sh && \
    echo '' >> /workspace/extract-images.sh && \
    echo 'if [ -f "$DEPLOY_DIR/bl1.bin" ]; then' >> /workspace/extract-images.sh && \
    echo '    cp "$DEPLOY_DIR/bl1.bin" "$OUTPUT_DIR/"' >> /workspace/extract-images.sh && \
    echo '    echo "✓ Copied bl1.bin"' >> /workspace/extract-images.sh && \
    echo 'else' >> /workspace/extract-images.sh && \
    echo '    echo "✗ bl1.bin not found"' >> /workspace/extract-images.sh && \
    echo 'fi' >> /workspace/extract-images.sh && \
    echo '' >> /workspace/extract-images.sh && \
    echo 'if [ -f "$DEPLOY_DIR/es_flashfw.bin" ]; then' >> /workspace/extract-images.sh && \
    echo '    cp "$DEPLOY_DIR/es_flashfw.bin" "$OUTPUT_DIR/"' >> /workspace/extract-images.sh && \
    echo '    echo "✓ Copied es_flashfw.bin"' >> /workspace/extract-images.sh && \
    echo 'else' >> /workspace/extract-images.sh && \
    echo '    echo "✗ es_flashfw.bin not found"' >> /workspace/extract-images.sh && \
    echo 'fi' >> /workspace/extract-images.sh && \
    echo '' >> /workspace/extract-images.sh && \
    echo 'if [ -f "$DEPLOY_DIR/corstone1000-image-corstone1000-fvp.wic.nopt" ]; then' >> /workspace/extract-images.sh && \
    echo '    cp "$DEPLOY_DIR/corstone1000-image-corstone1000-fvp.wic.nopt" "$OUTPUT_DIR/"' >> /workspace/extract-images.sh && \
    echo '    echo "✓ Copied corstone1000-image-corstone1000-fvp.wic.nopt"' >> /workspace/extract-images.sh && \
    echo 'else' >> /workspace/extract-images.sh && \
    echo '    echo "✗ corstone1000-image-corstone1000-fvp.wic.nopt not found"' >> /workspace/extract-images.sh && \
    echo 'fi' >> /workspace/extract-images.sh && \
    echo '' >> /workspace/extract-images.sh && \
    echo 'if [ -f "$DEPLOY_DIR/corstone1000-flash-firmware-image-corstone1000-fvp.wic" ]; then' >> /workspace/extract-images.sh && \
    echo '    cp "$DEPLOY_DIR/corstone1000-flash-firmware-image-corstone1000-fvp.wic" "$OUTPUT_DIR/"' >> /workspace/extract-images.sh && \
    echo '    echo "✓ Copied corstone1000-flash-firmware-image-corstone1000-fvp.wic"' >> /workspace/extract-images.sh && \
    echo 'else' >> /workspace/extract-images.sh && \
    echo '    echo "✗ corstone1000-flash-firmware-image-corstone1000-fvp.wic not found"' >> /workspace/extract-images.sh && \
    echo 'fi' >> /workspace/extract-images.sh && \
    echo '' >> /workspace/extract-images.sh && \
    echo 'if [ -f "$DEPLOY_DIR/cc312_otp.bin" ]; then' >> /workspace/extract-images.sh && \
    echo '    cp "$DEPLOY_DIR/cc312_otp.bin" "$OUTPUT_DIR/"' >> /workspace/extract-images.sh && \
    echo '    echo "✓ Copied cc312_otp.bin"' >> /workspace/extract-images.sh && \
    echo 'else' >> /workspace/extract-images.sh && \
    echo '    echo "✗ cc312_otp.bin not found"' >> /workspace/extract-images.sh && \
    echo 'fi' >> /workspace/extract-images.sh && \
    echo '' >> /workspace/extract-images.sh && \
    echo 'echo ""' >> /workspace/extract-images.sh && \
    echo 'echo "All files in deploy directory:"' >> /workspace/extract-images.sh && \
    echo 'ls -la "$DEPLOY_DIR/"' >> /workspace/extract-images.sh && \
    echo 'echo ""' >> /workspace/extract-images.sh && \
    echo 'echo "Extracted files:"' >> /workspace/extract-images.sh && \
    echo 'ls -la "$OUTPUT_DIR/"' >> /workspace/extract-images.sh && \
    echo 'echo ""' >> /workspace/extract-images.sh && \
    echo 'echo "Build artifacts extracted to /output/"' >> /workspace/extract-images.sh

RUN chmod +x /workspace/extract-images.sh

# Create FVP run script template
RUN echo '#!/bin/bash' > /workspace/run-fvp-template.sh && \
    echo '# Template script to run Corstone-1000 FVP with built images' >> /workspace/run-fvp-template.sh && \
    echo '# Adjust paths as needed for your setup' >> /workspace/run-fvp-template.sh && \
    echo '' >> /workspace/run-fvp-template.sh && \
    echo 'FVP_BINARY="/opt/corstone-1000/models/Linux64_armv8l_GCC-9.3/FVP_Corstone-1000"' >> /workspace/run-fvp-template.sh && \
    echo 'IMAGES_DIR="./corstone1000-images"' >> /workspace/run-fvp-template.sh && \
    echo '' >> /workspace/run-fvp-template.sh && \
    echo '# Basic FVP command - adjust parameters as needed' >> /workspace/run-fvp-template.sh && \
    echo '$FVP_BINARY \' >> /workspace/run-fvp-template.sh && \
    echo '    -C diagnostics=4 \' >> /workspace/run-fvp-template.sh && \
    echo '    -C se.trustedBootROMloader.fname="$IMAGES_DIR/bl1.bin" \' >> /workspace/run-fvp-template.sh && \
    echo '    -C se.trustedSRAM_config=6 \' >> /workspace/run-fvp-template.sh && \
    echo '    -C se.BootROM_config="3" \' >> /workspace/run-fvp-template.sh && \
    echo '    --data board.flash0="$IMAGES_DIR/corstone1000-image-corstone1000-fvp.wic.nopt@0x68050000" \' >> /workspace/run-fvp-template.sh && \
    echo '    -C board.xnvm_size=64 \' >> /workspace/run-fvp-template.sh && \
    echo '    -C board.smsc_91c111.enabled=1 \' >> /workspace/run-fvp-template.sh && \
    echo '    -C board.hostbridge.userNetworking=true \' >> /workspace/run-fvp-template.sh && \
    echo '    -C board.se_flash_size=8192' >> /workspace/run-fvp-template.sh

RUN chmod +x /workspace/run-fvp-template.sh

# Default command runs the extraction script
CMD ["/workspace/extract-images.sh"]