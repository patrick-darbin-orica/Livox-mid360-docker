# Livox Mid-360 LiDAR Docker Setup for Jetson Orin

Complete Docker-based setup for the Livox Mid-360 LiDAR on NVIDIA Jetson Orin platforms, including ROS2 Humble, FAST-LIO SLAM, RViz2 visualization, and data recording capabilities.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Hardware Requirements](#hardware-requirements)
- [Network Configuration](#network-configuration)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Launch Files](#launch-files)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Data Recording and Playback](#data-recording-and-playback)
- [Advanced Topics](#advanced-topics)

---

## Overview

This Docker setup provides a complete environment for working with the Livox Mid-360 LiDAR sensor on Jetson Orin platforms. It includes:

- **Livox-SDK2**: Core driver for Mid-360 LiDAR
- **livox_ros_driver2**: ROS2 Humble wrapper
- **FAST-LIO**: Real-time LiDAR-Inertial Odometry and mapping
- **RViz2**: 3D visualization
- **rosbag2**: Data recording and playback utilities

### Platform Specifications

- **Supported Platform**: NVIDIA Jetson Orin (AGX Orin, Orin NX, Orin Nano)
- **Operating System**: Ubuntu 22.04 LTS
- **JetPack Version**: JetPack 6.0 (L4T R36.x)
- **ROS Distribution**: ROS2 Humble
- **Architecture**: ARM64 (aarch64)
- **Docker**: NVIDIA Container Runtime required

---

## Prerequisites

### 1. Jetson Orin Setup

Ensure your Jetson Orin is running:
- **JetPack 6.0** (includes Ubuntu 22.04)
- **L4T R36.x** (Linux for Tegra)

Check your version:
```bash
cat /etc/nv_tegra_release
# Should show: R36 (release), REVISION: x.x
```

### 2. Install NVIDIA Container Runtime

```bash
# Add NVIDIA Container Toolkit GPG key (modern method)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Add NVIDIA Container Toolkit repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Update package list and install nvidia-docker2
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# Restart Docker service
sudo systemctl restart docker

# Verify installation
sudo docker info | grep -i runtime
```

You should see `nvidia` in the runtimes list.

**Note**: This method uses the modern GPG keyring approach instead of the deprecated `apt-key` command, and automatically uses the correct repository for Ubuntu 22.04.

### 3. Install Docker Compose (if not already installed)

```bash
sudo apt-get install -y docker-compose
```

---

## Hardware Requirements

### Minimum Requirements

- **Jetson Orin Nano**: 8GB RAM
- **Jetson Orin NX**: 8GB/16GB RAM
- **Jetson AGX Orin**: 32GB/64GB RAM
- **Storage**: 32GB minimum (64GB+ recommended for data recording)
- **Network**: Gigabit Ethernet port

### LiDAR Hardware

- **Livox Mid-360 LiDAR**
- Ethernet cable (CAT5e or better)
- Power supply for Mid-360 (24V DC, provided with LiDAR)

---

## Network Configuration

The Livox Mid-360 uses a **static IP configuration only** (no DHCP support).

### Default LiDAR Settings

- **IP Address**: `192.168.1.1XX` (where XX = last two digits of serial number)
- **Subnet Mask**: `255.255.255.0`
- **Gateway**: `192.168.1.1`

Most Mid-360 units ship with IP: `192.168.1.12`

### Configure Host Network Interface

You need to configure your Jetson's Ethernet interface with a static IP in the same subnet.

#### Option 1: Using NetworkManager (GUI)

1. Open Network Settings
2. Select the Ethernet connection connected to the LiDAR
3. Click the gear icon
4. Go to IPv4 tab
5. Select "Manual" method
6. Set:
   - **Address**: `192.168.1.5`
   - **Netmask**: `255.255.255.0`
   - **Gateway**: `192.168.1.1`
7. Apply and reconnect

#### Option 2: Using Command Line (netplan)

Create or edit `/etc/netplan/01-livox-static.yaml`:

```yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eth0:  # Replace with your interface name (check with 'ip addr')
      dhcp4: no
      addresses:
        - 192.168.1.5/24
      routes:
        - to: 192.168.1.0/24
          via: 192.168.1.1
```

Apply the configuration:
```bash
sudo netplan apply
```

#### Verify Network Configuration

```bash
# Check IP address
ip addr show

# Ping the LiDAR
ping 192.168.1.12
```

You should see successful ping responses if the LiDAR is powered and connected.

---

## Quick Start

### 1. Clone or Navigate to Project Directory

```bash
cd /home/user/Programs/Livox-mid360-docker
```

### 2. Build the Docker Image

```bash
chmod +x build.sh
sudo ./build.sh
```

This will:
- Check for NVIDIA Container Runtime
- Create necessary directories
- Build the Docker image (this may take 30-60 minutes on Jetson)

### 3. Start the Container

```bash
./run.sh
```

This will:
- Configure X11 forwarding for RViz2
- Verify network configuration
- Start the Docker container

### 4. Access the Container

```bash
docker exec -it livox_mid360_container bash
```

### 5. Test LiDAR Connection

Inside the container:
```bash
# Source ROS2 environment (already done in .bashrc, but just to be sure)
source /opt/ros/humble/setup.bash
source /root/livox_ws/install/setup.bash

# Launch basic driver
ros2 launch livox_ros_driver2 msg_MID360_launch.py
```

You should see point cloud data streaming. Press `Ctrl+C` to stop.

---

## Usage

### Launch Files

The project includes four launch files for different use cases:

#### 1. Basic LiDAR Driver

Launches only the LiDAR driver without visualization.

```bash
ros2 launch /root/livox_ws/launch/livox_driver.launch.py
```

**Topics published**:
- `/livox/pointcloud` - Point cloud data
- `/livox/imu` - IMU data

#### 2. LiDAR with RViz2 Visualization

Launches driver with RViz2 for real-time 3D visualization.

```bash
ros2 launch /root/livox_ws/launch/livox_rviz.launch.py
```

**Features**:
- Real-time point cloud visualization
- IMU data display
- Transform tree (TF)

#### 3. LiDAR with FAST-LIO SLAM

Launches driver with FAST-LIO for real-time odometry and mapping.

```bash
ros2 launch /root/livox_ws/launch/livox_fastlio.launch.py
```

**Topics published** (in addition to driver topics):
- `/fast_lio/cloud_registered` - Registered point cloud map
- `/fast_lio/odometry` - LiDAR-Inertial odometry
- `/fast_lio/path` - Trajectory path

#### 4. Data Recording

Launches driver and records data to rosbag2 format.

```bash
ros2 launch /root/livox_ws/launch/livox_record.launch.py
```

**Recorded topics**:
- `/livox/pointcloud`
- `/livox/imu`
- `/tf`
- `/tf_static`

**Data location**: `/root/livox_ws/data/livox_mid360_YYYYMMDD_HHMMSS/`

---

## Configuration

### LiDAR Configuration

Edit [config/MID360_config.json](config/MID360_config.json) to customize:

#### Network Settings

```json
"host_net_info": {
  "cmd_data_ip": "192.168.1.5",    // Your Jetson IP
  "point_data_ip": "192.168.1.5"
}
```

```json
"lidar_configs": [
  {
    "ip": "192.168.1.12",           // Your LiDAR IP
    "pcl_data_type": 1,             // 1=32-bit Cartesian, 2=16-bit, 3=Spherical
    "pattern_mode": 0               // 0=non-repeating, 1=repeating
  }
]
```

#### Extrinsic Calibration

If your LiDAR is mounted at an offset or rotation:

```json
"extrinsic_parameter": {
  "roll": 0.0,   // Rotation around X-axis (degrees)
  "pitch": 0.0,  // Rotation around Y-axis (degrees)
  "yaw": 0.0,    // Rotation around Z-axis (degrees)
  "x": 0.0,      // Translation in X (meters)
  "y": 0.0,      // Translation in Y (meters)
  "z": 0.0       // Translation in Z (meters)
}
```

### FAST-LIO Configuration

Edit [config/fastlio_mid360.yaml](config/fastlio_mid360.yaml):

#### Key Parameters

```yaml
common:
  lid_topic: "/livox/lidar"
  imu_topic: "/livox/imu"
  time_sync_en: false              // Enable external time sync if available

preprocess:
  lidar_type: 1                    // 1 for Livox LiDAR
  blind: 0.5                       // Minimum range (meters)

mapping:
  det_range: 100.0                 // Maximum detection range
  extrinsic_est_en: true           // Enable online extrinsic calibration
```

---

## Troubleshooting

### No Point Cloud Data

**Problem**: Driver launches but no data is received.

**Solutions**:

1. **Check network connectivity**:
   ```bash
   ping 192.168.1.12
   ```

2. **Verify LiDAR IP** in `config/MID360_config.json` matches your device

3. **Check firewall rules**:
   ```bash
   # Inside container
   sudo ufw status
   # If active, allow UDP ports
   sudo ufw allow 56100:56500/udp
   ```

4. **Verify LiDAR is spinning**: You should hear the motor running

### RViz2 Not Displaying

**Problem**: RViz2 opens but shows black screen or errors.

**Solutions**:

1. **Check X11 forwarding**:
   ```bash
   # On host (outside container)
   xhost +local:docker
   echo $DISPLAY  # Should show :0 or :1
   ```

2. **Verify DISPLAY variable** inside container:
   ```bash
   echo $DISPLAY
   ```

3. **Test with simple visualization**:
   ```bash
   ros2 run rviz2 rviz2
   ```

### Docker Build Fails

**Problem**: Build script fails during compilation.

**Solutions**:

1. **Check available disk space**:
   ```bash
   df -h
   ```
   You need at least 10GB free.

2. **Increase swap space** (Jetson Orin Nano/NX):
   ```bash
   sudo systemctl disable nvzramconfig
   sudo fallocate -l 8G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

3. **Clear Docker cache**:
   ```bash
   docker system prune -a
   ```

### FAST-LIO Crashes or High CPU Usage

**Problem**: FAST-LIO consumes too much CPU or crashes.

**Solutions**:

1. **Reduce point cloud density** in `config/fastlio_mid360.yaml`:
   ```yaml
   publish:
     dense_publish_en: false
   ```

2. **Increase blind distance**:
   ```yaml
   preprocess:
     blind: 1.0  # Increase from 0.5
   ```

3. **Enable Jetson power mode**:
   ```bash
   # On host
   sudo nvpmodel -m 0  # MAXN mode
   sudo jetson_clocks   # Maximize clock speeds
   ```

### Container Won't Start

**Problem**: `docker-compose up` fails or container exits immediately.

**Solutions**:

1. **Check NVIDIA runtime**:
   ```bash
   docker info | grep -i runtime
   ```

2. **Verify image was built**:
   ```bash
   docker images | grep livox
   ```

3. **Check logs**:
   ```bash
   docker-compose logs
   ```

---

## Data Recording and Playback

### Recording Data

#### Using Launch File

```bash
ros2 launch /root/livox_ws/launch/livox_record.launch.py
```

Data will be saved to `/root/livox_ws/data/livox_mid360_YYYYMMDD_HHMMSS/`

#### Manual Recording

```bash
# Record specific topics
ros2 bag record /livox/pointcloud /livox/imu -o /root/livox_ws/data/my_recording

# Record all topics
ros2 bag record -a -o /root/livox_ws/data/all_topics
```

### Playback Recorded Data

```bash
# List recorded topics
ros2 bag info /root/livox_ws/data/livox_mid360_YYYYMMDD_HHMMSS

# Play back data
ros2 bag play /root/livox_ws/data/livox_mid360_YYYYMMDD_HHMMSS
```

### Accessing Recorded Data from Host

Recorded data is stored in the `data/` directory which is mounted from the host:

```bash
# On host (outside container)
ls -lh /home/user/Programs/Livox-mid360-docker/data/
```

You can copy files from here for processing on other systems.

---

## Advanced Topics

### Changing LiDAR IP Address

If you need to change your Mid-360's IP address, use the Livox Viewer software on a Windows PC or:

1. Install `livox_scanner` tool (not included in this Docker)
2. Use the Livox SDK2 configuration API

Reference: [Livox SDK2 Documentation](https://github.com/Livox-SDK/Livox-SDK2)

### Multi-LiDAR Setup

To use multiple Mid-360 units:

1. Edit `config/MID360_config.json`
2. Add additional entries to `lidar_configs` array:

```json
"lidar_configs": [
  {
    "ip": "192.168.1.12",
    "pcl_data_type": 1,
    "pattern_mode": 0
  },
  {
    "ip": "192.168.1.13",
    "pcl_data_type": 1,
    "pattern_mode": 0
  }
]
```

3. Set `multi_topic: 1` in launch files to get separate topics per LiDAR

### Performance Tuning

#### Jetson Power Modes

```bash
# On host
sudo nvpmodel -q  # Query current mode
sudo nvpmodel -m 0  # Set to MAXN (maximum performance)
sudo jetson_clocks  # Lock clocks to maximum
```

#### Docker Resource Limits

Edit `docker-compose.yml` to limit resources:

```yaml
services:
  livox_mid360:
    # ... existing configuration ...
    deploy:
      resources:
        limits:
          cpus: '6'
          memory: 16G
```

### Integration with Other ROS2 Packages

The point cloud data is published as standard ROS2 messages and can be used with:

- **Navigation2**: For robot navigation
- **Cartographer**: For 2D/3D SLAM
- **PCL**: For point cloud processing
- **LOAM**: For odometry and mapping

Example: Subscribing to point cloud in your own node:

```python
import rclpy
from sensor_msgs.msg import PointCloud2

class LidarSubscriber(Node):
    def __init__(self):
        super().__init__('lidar_subscriber')
        self.subscription = self.create_subscription(
            PointCloud2,
            '/livox/pointcloud',
            self.listener_callback,
            10)

    def listener_callback(self, msg):
        self.get_logger().info(f'Received point cloud with {msg.width} points')
```

---

## Container Management

### Stop Container

```bash
docker-compose down
```

### Restart Container

```bash
docker-compose restart
```

### View Logs

```bash
docker-compose logs -f
```

### Remove Container and Image

```bash
docker-compose down
docker rmi livox-mid360-jetson-orin:latest
```

### Rebuild from Scratch

```bash
docker-compose down
docker system prune -a  # Clean up
./build.sh
```

---

## Directory Structure

```
Livox Lidar/
├── Dockerfile                      # Docker image definition
├── docker-compose.yml              # Docker Compose configuration
├── build.sh                        # Build script
├── run.sh                          # Run script
├── .dockerignore                   # Docker ignore file
├── config/
│   ├── MID360_config.json         # LiDAR configuration
│   └── fastlio_mid360.yaml        # FAST-LIO configuration
├── launch/
│   ├── livox_driver.launch.py     # Basic driver launch
│   ├── livox_rviz.launch.py       # Driver + RViz2 launch
│   ├── livox_fastlio.launch.py    # Driver + FAST-LIO launch
│   └── livox_record.launch.py     # Recording launch
├── data/                           # Recorded data (created at runtime)
└── README.md                       # This file
```

---

## References

- [Livox-SDK2 GitHub](https://github.com/Livox-SDK/Livox-SDK2)
- [livox_ros_driver2 GitHub](https://github.com/Livox-SDK/livox_ros_driver2)
- [FAST-LIO GitHub](https://github.com/hku-mars/FAST_LIO)
- [Livox Mid-360 Documentation](https://www.livoxtech.com/mid-360)
- [ROS2 Humble Documentation](https://docs.ros.org/en/humble/)
- [Jetson Orin Documentation](https://developer.nvidia.com/embedded/jetson-orin)

---

## License

This Docker setup configuration is provided as-is. Individual components have their own licenses:
- Livox-SDK2: MIT License
- FAST-LIO: GPLv2
- ROS2: Apache 2.0

---

## Support and Contributing

For issues related to:
- **Livox SDK/Driver**: [Livox-SDK2 Issues](https://github.com/Livox-SDK/Livox-SDK2/issues)
- **FAST-LIO**: [FAST-LIO Issues](https://github.com/hku-mars/FAST_LIO/issues)
- **This Docker Setup**: Create an issue in your project repository

---

**Last Updated**: 2025-11-12
