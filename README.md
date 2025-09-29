# Ubuntu Nix DevContainer

A Docker image providing Ubuntu 24.04 with Nix package manager for development environments, optimized for DevSpace and Kubernetes deployments.

## 🔧 Permission Fixes Applied

The Docker configurations have been updated to fix permission issues when using with DevSpace:

### Key Improvements:
- **Enhanced Directory Permissions**: Added `/workspace` directory with 775 permissions and sticky bit
- **DevSpace Sync Compatibility**: Fixed file sync permission errors
- **Auto-permission Repair**: Entrypoint script automatically fixes permissions on container start
- **Dual Dockerfile Support**: Added `Dockerfile.backstage-nix` optimized for Backstage development
- **Home-manager Integration**: Automatically runs `nix run home-manager -- switch --flake github:vpittamp/nixos-config#code` on startup
- **Conflict Resolution**: Removes `.bashrc` and `.profile` files that prevent home-manager builds

## Features

- **Base**: Ubuntu 24.04 LTS (Noble Numbat) or Node.js 20 (Backstage variant)
- **Nix**: Latest version installed in single-user mode
- **Non-root user**: Runs as user `code` (UID 1001) or `node` (UID 1000)
- **DevSpace compatible**: Pre-configured `/workspace` and `/home/code/app` directories with correct permissions
- **Development ready**: Includes git, curl, build-essential, sudo access, and development tools

## Quick Start

### Build the images

```bash
# Build basic Ubuntu + Nix image
docker build -t ubuntu-nix-nonroot:latest .

# Build Backstage + Nix optimized image
docker build -f Dockerfile.backstage-nix -t backstage-nix:latest .

# Or use the build script
./build-nix-image.sh

# Or use docker-compose
docker-compose build
```

### Run the container

```bash
docker run -it --rm ubuntu-nix-nonroot:latest bash
```

### Use with DevSpace

The images are designed to work seamlessly with DevSpace file synchronization. Both `/workspace` and `/home/code/app` directories are pre-created with correct ownership to prevent permission issues.

```yaml
# devspace.yaml example for Backstage development
dev:
  app:
    namespace: backstage
    labelSelector:
      app: backstage-dev
    container: backstage

    # Use the optimized Backstage + Nix image
    devImage: backstage-nix:latest

    # Override resources for development
    resources:
      limits:
        cpu: "2"
        memory: "4Gi"
      requests:
        cpu: "500m"
        memory: "1Gi"

    # Sync configuration
    sync:
      - path: ./:/workspace
        excludePaths:
        - node_modules/
        - .git/
        - dist/
```

## Home-manager Configuration

The containers automatically initialize home-manager with the configuration from `github:vpittamp/nixos-config#code` on first startup. This provides:
- Custom shell environment (bash, zsh configurations)
- Development tools and utilities
- AI CLI tools (claude, gemini, codex, aichat)
- Personalized dotfiles

### Manual Initialization
If home-manager doesn't initialize automatically, you can run it manually:
```bash
# Inside the container
./init-home-manager.sh

# Or directly
nix run home-manager -- switch --flake github:vpittamp/nixos-config#code --impure
```

### Troubleshooting Home-manager
If you encounter errors during home-manager initialization:
1. **Conflicting files**: The container automatically removes `.bashrc`, `.profile`, and `.bash_profile` to prevent conflicts
2. **Network issues**: Ensure the container has internet access to fetch the flake from GitHub
3. **Permission issues**: The initialization runs as the container user (node/code) with proper permissions

## Nix Usage

The container comes with Nix pre-installed and configured with nixpkgs-unstable channel:

```bash
# Install packages
nix-env -iA nixpkgs.nodejs nixpkgs.python3

# Use nix-shell
nix-shell -p nodejs python3

# Enable flakes (already configured)
nix --experimental-features 'nix-command flakes' develop
```

## Environment Variables

- `USER=code`
- `HOME=/home/code`
- `PATH` includes `/home/code/.nix-profile/bin`
- `NIX_CONFIG` enables experimental features (nix-command and flakes)

## Directory Structure

- `/home/code` - User home directory
- `/home/code/app` - Application working directory (DevSpace sync target)
- `/nix` - Nix store and profiles
- `/home/code/.nix-profile` - User's Nix profile

## Security

- Runs as non-root user (UID 1001)
- User has passwordless sudo for development convenience
- Suitable for development environments

## License

MIT