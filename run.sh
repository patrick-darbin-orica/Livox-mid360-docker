#!/bin/bash

# Run script for Livox Mid-360 Docker container on Jetson Orin
# This script starts the Docker container with proper configuration

set -e  # Exit on error

echo "========================================="
echo "Starting Livox Mid-360 Docker Container"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if image exists
if ! docker images | grep -q livox-mid360-jetson-orin; then
    echo -e "${RED}ERROR: Docker image not found!${NC}"
    echo "Please build the image first using: ./build.sh"
    exit 1
fi

# Allow X11 forwarding for RViz2
echo -e "${GREEN}Setting up X11 forwarding...${NC}"
xhost +local:docker > /dev/null 2>&1 || echo -e "${YELLOW}Warning: Could not configure X11. RViz2 may not work.${NC}"

# Check network interface
echo -e "${GREEN}Checking network configuration...${NC}"
if ip addr show | grep -q "192.168.1.5"; then
    echo -e "${GREEN}Network interface configured correctly (192.168.1.5)${NC}"
else
    echo -e "${YELLOW}Warning: Static IP 192.168.1.5 not detected.${NC}"
    echo "Please configure your network interface with:"
    echo "  IP: 192.168.1.5"
    echo "  Subnet: 255.255.255.0"
    echo ""
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Startup cancelled."
        exit 0
    fi
fi

# Create data directory if it doesn't exist
mkdir -p data

# Start container using docker-compose
echo -e "${GREEN}Starting container...${NC}"
docker-compose up -d

# Wait for container to be ready
sleep 2

# Check if container is running
if docker ps | grep -q livox_mid360_container; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}Container started successfully!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "To access the container, run:"
    echo "  docker exec -it livox_mid360_container bash"
    echo ""
    echo "Available launch commands inside the container:"
    echo "  ros2 launch livox_ros_driver2 msg_MID360_launch.py   # Basic driver"
    echo "  ros2 launch /root/livox_ws/launch/livox_rviz.launch.py   # With RViz2"
    echo "  ros2 launch /root/livox_ws/launch/livox_fastlio.launch.py   # With FAST-LIO"
    echo "  ros2 launch /root/livox_ws/launch/livox_record.launch.py   # Record data"
    echo ""
    echo "To stop the container, run:"
    echo "  docker-compose down"
else
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}Failed to start container!${NC}"
    echo -e "${RED}=========================================${NC}"
    echo "Check logs with: docker-compose logs"
    exit 1
fi
