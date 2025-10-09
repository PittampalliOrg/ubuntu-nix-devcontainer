# Backstage + Nix Development Container with persistent /nix volume support
# Optimized for DevSpace with PVC-mounted /nix directory

FROM node:20-bullseye AS base

# Install system dependencies needed for Nix
RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    sudo \
    ca-certificates \
    git \
    build-essential \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Rename node user/group to code to match nixos-config expectations
# The node image already has node:node with UID/GID 1000
RUN groupmod -n code node && \
    usermod -l code -d /home/code -m node && \
    echo "code ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Create necessary directories
RUN mkdir -p /workspace /home/code/app /nix /tmp/nix-build && \
    chown -R code:code /workspace /home/code /tmp/nix-build && \
    chmod -R 775 /workspace /home/code/app && \
    # Set sticky bit to preserve ownership
    chmod g+s /workspace /home/code/app

# Remove any existing nixbld1 user that might conflict
RUN userdel nixbld1 2>/dev/null || true && \
    groupdel nixbld 2>/dev/null || true

# Create Nix build users/group for multi-user installation with proper UIDs
RUN groupadd -r nixbld -g 30000 && \
    for i in $(seq 1 32); do \
        useradd -r -g nixbld -G nixbld -d /var/empty -s /sbin/nologin -u $((30000 + i)) nixbld$i; \
    done

# Switch to code user
USER code
WORKDIR /home/code

# Set environment for code user
ENV USER=code
ENV HOME=/home/code

# Create a simpler entrypoint that just ensures environment is ready
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Function to install Nix if not present\n\
install_nix_if_needed() {\n\
    if [ ! -d "/nix/store" ] || [ ! -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then\n\
        echo "📦 Installing Nix (first run with this volume)..."\n\
        echo "This will take a few minutes..."\n\
        \n\
        # Download and run Nix installer\n\
        curl -L https://nixos.org/nix/install > /tmp/install-nix.sh\n\
        chmod +x /tmp/install-nix.sh\n\
        \n\
        # Run installer with multi-user mode\n\
        sudo bash /tmp/install-nix.sh --daemon --yes\n\
        \n\
        echo "✅ Nix installation completed!"\n\
    fi\n\
}\n\
\n\
# Function to start Nix daemon\n\
start_nix_daemon() {\n\
    # Check if daemon is running\n\
    if ! pgrep -x nix-daemon > /dev/null; then\n\
        echo "🔧 Starting Nix daemon..."\n\
        sudo /nix/var/nix/profiles/default/bin/nix-daemon > /tmp/nix-daemon.log 2>&1 &\n\
        # Give daemon time to start and create socket\n\
        for i in {1..10}; do\n\
            if [ -S /nix/var/nix/daemon-socket/socket ]; then\n\
                echo "✅ Nix daemon started successfully"\n\
                break\n\
            fi\n\
            sleep 1\n\
        done\n\
    fi\n\
}\n\
\n\
# Function to setup Nix environment\n\
setup_nix_env() {\n\
    # Source Nix environment\n\
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then\n\
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh\n\
    elif [ -f /home/code/.nix-profile/etc/profile.d/nix.sh ]; then\n\
        . /home/code/.nix-profile/etc/profile.d/nix.sh\n\
    fi\n\
    \n\
    export NIX_CONFIG="experimental-features = nix-command flakes"\n\
    export PATH="/nix/var/nix/profiles/default/bin:/home/code/.nix-profile/bin:$PATH"\n\
}\n\
\n\
# Main initialization flow\n\
install_nix_if_needed\n\
start_nix_daemon\n\
setup_nix_env\n\
\n\
# Ensure workspace permissions\n\
if [ -d /workspace ]; then\n\
    sudo chown -R code:code /workspace 2>/dev/null || true\n\
    sudo chmod -R 775 /workspace 2>/dev/null || true\n\
fi\n\
\n\
# Export environment for child processes\n\
export NODE_OPTIONS="--max-old-space-size=16384"\n\
export YARN_CACHE_FOLDER="/home/code/.cache/yarn"\n\
export npm_config_cache="/home/code/.cache/npm"\n\
\n\
# Setup home-manager if not already initialized\n\
if [ ! -f /home/code/.config/home-manager/.initialized ]; then\n\
    echo ""\n\
    echo "✨ Container ready! Initializing home-manager..."\n\
    echo ""\n\
    \n\
    # Clean up any existing nix profile packages to avoid conflicts\n\
    if nix profile list 2>/dev/null | grep -q "home-manager-path"; then\n\
        echo "🗑️  Cleaning up existing nix profile packages..."\n\
        nix profile remove home-manager-path 2>/dev/null || true\n\
    fi\n\
    \n\
    # Remove pre-existing shell config files that would conflict with home-manager\n\
    echo "🧹 Removing pre-existing shell config files..."\n\
    rm -f /home/code/.bashrc /home/code/.profile /home/code/.bash_profile 2>/dev/null || true\n\
    \n\
    # Initialize home-manager configuration\n\
    echo "🏠 Activating home-manager configuration..."\n\
    if nix run home-manager -- switch --flake github:vpittamp/nixos-config#code --impure; then\n\
        echo "✅ Home-manager activated successfully!"\n\
        mkdir -p /home/code/.config/home-manager\n\
        touch /home/code/.config/home-manager/.initialized\n\
    else\n\
        echo "⚠️  Home-manager activation failed. You can retry manually with:"\n\
        echo "  curl -L https://raw.githubusercontent.com/vpittamp/nixos-config/main/scripts/codespaces-setup.sh | bash"\n\
    fi\n\
    echo ""\n\
else\n\
    echo ""\n\
    echo "✨ Container ready! Home-manager already initialized."\n\
    echo "To update: curl -L https://raw.githubusercontent.com/vpittamp/nixos-config/main/scripts/codespaces-setup.sh | bash"\n\
    echo ""\n\
fi\n\
\n\
# Execute the provided command or start bash\n\
if [ "$#" -eq 0 ]; then\n\
    exec /bin/bash\n\
else\n\
    exec "$@"\n\
fi' > /home/code/entrypoint.sh && \
    chmod +x /home/code/entrypoint.sh

# Don't pre-create shell config files - let home-manager manage them
# Home-manager will create these files with the correct configuration

# Set working directory to /workspace for DevSpace
WORKDIR /workspace

# Copy package files if they exist (for caching)
# These will be overridden by DevSpace sync
ONBUILD COPY --chown=code:code package*.json yarn.lock* ./
ONBUILD RUN yarn install --frozen-lockfile --network-timeout 600000 || true

# Set proper environment variables
ENV PATH="/nix/var/nix/profiles/default/bin:/home/code/.nix-profile/bin:/home/code/.yarn/bin:/home/code/.config/yarn/global/node_modules/.bin:$PATH"
ENV NODE_ENV=development
ENV NIX_CONFIG="experimental-features = nix-command flakes"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "console.log('OK')" || exit 1

# Use our custom entrypoint
ENTRYPOINT ["/home/code/entrypoint.sh"]

# Default command for development
CMD ["sleep", "infinity"]