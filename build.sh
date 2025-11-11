#!/bin/bash

# Build script for Livox Mid-360 Docker image on Jetson Orin
# This script builds the Docker image with proper NVIDIA runtime support

set -e  # Exit on error

echo "========================================="
echo "Building Livox Mid-360 Docker Image"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running on Jetson
if [ ! -f /etc/nv_tegra_release ]; then
    echo -e "${YELLOW}Warning: This does not appear to be a Jetson device.${NC}"
    echo "This image is optimized for Jetson Orin. Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Build cancelled."
        exit 0
    fi
fi

# Check if NVIDIA Container Runtime is installed
if ! docker info | grep -q nvidia; then
    echo -e "${RED}ERROR: NVIDIA Container Runtime not detected!${NC}"
    echo "Please install nvidia-docker2:"
    echo "  sudo apt-get install nvidia-docker2"
    echo "  sudo systemctl restart docker"
    exit 1
fi

# Create necessary directories
echo -e "${GREEN}Creating directory structure...${NC}"
mkdir -p config
mkdir -p launch
mkdir -p data

# Build the Docker image
echo -e "${GREEN}Building Docker image...${NC}"
docker-compose build --no-cache

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "To run the container, execute: ./run.sh"
    echo "Or use: docker-compose up -d"
else
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}Build failed!${NC}"
    echo -e "${RED}=========================================${NC}"
    exit 1
fi
