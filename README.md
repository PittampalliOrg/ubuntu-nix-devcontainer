# Ubuntu Nix DevContainer

A Docker image providing Ubuntu 24.04 with Nix package manager for development environments, optimized for DevSpace and Kubernetes deployments.

## Features

- **Base**: Ubuntu 24.04 LTS (Noble Numbat)
- **Nix**: Version 2.31.1 installed in single-user mode
- **Non-root user**: Runs as user `code` (UID 1001, GID 100)
- **DevSpace compatible**: Pre-configured `/home/code/app` directory with correct permissions
- **Development ready**: Includes git, curl, build-essential, and sudo access

## Quick Start

### Build the image

```bash
docker build -t ubuntu-nix-nonroot:latest .
```

### Run the container

```bash
docker run -it --rm ubuntu-nix-nonroot:latest bash
```

### Use with DevSpace

The image is designed to work seamlessly with DevSpace file synchronization. The `/home/code/app` directory is pre-created with correct ownership to prevent permission issues.

```yaml
# devspace.yaml example
images:
  app:
    image: ubuntu-nix-nonroot
    dockerfile: ./Dockerfile

dev:
  app:
    imageSelector: ubuntu-nix-nonroot
    sync:
      - path: ./:/home/code/app
```

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