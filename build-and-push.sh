#!/usr/bin/env bash
# Build and push the Backstage + Nix image to Docker Hub

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Docker Hub configuration
DOCKER_HUB_USER="vpittamp23"
IMAGE_NAME="ubuntu-nix-backstage"
VERSION="v11"  # Fixed nixbld user conflicts

echo -e "${GREEN}Building Backstage with Nix and Home-manager support...${NC}"
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
    -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${VERSION} \
    -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest \
    .

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
echo ""

# Login to Docker Hub
echo -e "${YELLOW}Logging in to Docker Hub...${NC}"
if [ -t 0 ]; then
    echo "Please enter your Docker Hub password for user ${DOCKER_HUB_USER}:"
    docker login -u ${DOCKER_HUB_USER}
else
    echo "Non-interactive mode detected. Please login manually using:"
    echo "  docker login -u ${DOCKER_HUB_USER}"
    echo ""
    echo "Then push the images with:"
    echo "  docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${VERSION}"
    echo "  docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
    exit 0
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}Docker Hub login failed!${NC}"
    exit 1
fi

# Push the images
echo -e "${YELLOW}Pushing image with tag '${VERSION}'...${NC}"
docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${VERSION}

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to push version tag!${NC}"
    exit 1
fi

echo -e "${YELLOW}Pushing image with tag 'latest'...${NC}"
docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to push latest tag!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Images pushed successfully!${NC}"
echo ""
echo "Images available at:"
echo "  - docker.io/${DOCKER_HUB_USER}/${IMAGE_NAME}:${VERSION}"
echo "  - docker.io/${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
echo ""
echo "To use this image with DevSpace, update your devspace.yaml:"
echo "  devImage: ${DOCKER_HUB_USER}/${IMAGE_NAME}:${VERSION}"
echo ""
echo "Features included:"
echo "  ✅ Node.js 20 base image"
echo "  ✅ Nix package manager"
echo "  ✅ Home-manager auto-initialization"
echo "  ✅ Conflict resolution for .bashrc/.profile"
echo "  ✅ DevSpace sync compatibility"
echo "  ✅ Your nixos-config#code flake"