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
