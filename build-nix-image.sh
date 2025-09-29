#!/bin/bash
# Build and push the Backstage + Nix image with proper permissions

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building Backstage with Nix development container...${NC}"
echo ""

# Check if Dockerfile exists
if [ ! -f "Dockerfile.backstage-nix" ]; then
    echo -e "${RED}Error: Dockerfile.backstage-nix not found!${NC}"
    exit 1
fi

# Build the image with buildkit for better caching
echo -e "${YELLOW}Building image with Docker BuildKit...${NC}"
DOCKER_BUILDKIT=1 docker build \
    --progress=plain \
    -f Dockerfile.backstage-nix \
    -t backstage-nix:latest \
    -t backstage-nix:dev \
    .

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

# Tag for your registry
docker tag backstage-nix:latest gitea.cnoe.localtest.me:8443/giteaadmin/backstage-nix:latest
docker tag backstage-nix:latest gitea.cnoe.localtest.me:8443/giteaadmin/backstage-nix:dev

# Optional: Push to registry (uncomment if needed)
# echo -e "${YELLOW}Pushing to registry...${NC}"
# docker push gitea.cnoe.localtest.me:8443/giteaadmin/backstage-nix:latest
# docker push gitea.cnoe.localtest.me:8443/giteaadmin/backstage-nix:dev

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