# Reconstructed Dockerfile for vpittamp23/ubuntu-nix-nonroot:v4
# Based on Docker image inspection and layer analysis

# Base image: Ubuntu 24.04 (Noble Numbat)
FROM ubuntu:24.04

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    sudo \
    ca-certificates \
    git \
    build-essential \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user 'code' with UID 1001 and GID 100 (users group)
RUN useradd -m -u 1001 -g users -s /bin/bash code && \
    echo "code ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Create necessary directories with proper ownership
# IMPORTANT: Create /home/code/app with correct permissions for DevSpace sync
RUN mkdir -p /nix /tmp/nix-build /home/code/.local/state/nix/profiles /home/code/app && \
    chown -R code:users /nix /tmp/nix-build /home/code && \
    chmod -R 755 /home/code/app

# Switch to non-root user
USER code

# Set working directory to /home/code/app for DevSpace compatibility
WORKDIR /home/code/app

# Set environment variables
ENV USER=code
ENV HOME=/home/code
ENV PATH=/home/code/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV NIX_PATH=nixpkgs=/home/code/.nix-defexpr/channels/nixpkgs
ENV NIX_CONFIG="experimental-features = nix-command flakes"

# Install Nix in single-user mode (as observed from history)
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon

# Add nixpkgs-unstable channel and update
RUN . /home/code/.nix-profile/etc/profile.d/nix.sh && \
    nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
    nix-channel --update

# Verify Nix installation
RUN . /home/code/.nix-profile/etc/profile.d/nix.sh && \
    nix --version

# Create entrypoint script to ensure Nix environment is properly loaded
RUN echo '#!/bin/bash\n\
if [ -f /home/code/.nix-profile/etc/profile.d/nix.sh ]; then\n\
    . /home/code/.nix-profile/etc/profile.d/nix.sh\n\
fi\n\
export PATH="/home/code/.nix-profile/bin:$PATH"\n\
exec "$@"' > /home/code/entrypoint.sh && \
    chmod +x /home/code/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/home/code/entrypoint.sh"]

# Default command
CMD ["sleep", "infinity"]