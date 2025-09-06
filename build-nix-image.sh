#!/bin/bash
# Build and push the Backstage + Nix image

set -e

echo "Building Backstage with Nix and AI tools..."

# Build the image
docker build -f Dockerfile.backstage-nix -t backstage-nix:latest .

# Tag for your registry
docker tag backstage-nix:latest gitea.cnoe.localtest.me:8443/giteaadmin/backstage-nix:latest

# Optional: Push to registry (uncomment if needed)
# docker push gitea.cnoe.localtest.me:8443/giteaadmin/backstage-nix:latest

echo "Build complete!"
echo ""
echo "To use this image with DevSpace:"
echo "1. Edit devspace.yaml and change the image for backstage-dev to:"
echo "   image: backstage-nix:latest"
echo ""
echo "2. Or run DevSpace with override:"
echo "   devspace dev --skip-build --override-image backstage-dev=backstage-nix:latest"
echo ""
echo "The image includes:"
echo "  - Node.js 18 for Backstage"
echo "  - Nix package manager"
echo "  - Home-manager configuration"
echo "  - AI tools: claude, gemini, codex, aichat"