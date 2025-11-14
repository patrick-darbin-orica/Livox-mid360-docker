# Dockerfile for Livox Mid-360 LiDAR on Jetson Orin
# Base: NVIDIA L4T (Linux for Tegra) with CUDA support
# Target: Ubuntu 22.04, ROS2 Humble, ARM64 architecture
# JetPack 6.0 (L4T R36.x)

FROM nvcr.io/nvidia/l4t-base:r36.2.0

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble
ENV WORKSPACE=/root/livox_ws

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    gnupg2 \
    lsb-release \
    software-properties-common \
    locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8

# Add ROS2 repository
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Install ROS2 Humble Desktop (includes RViz2)
RUN apt-get update && apt-get install -y \
    ros-humble-desktop \
    ros-humble-pcl-ros \
    ros-humble-pcl-conversions \
    ros-humble-vision-opencv \
    python3-pip \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    libpcl-dev \
    libeigen3-dev \
    libgflags-dev \
    libgoogle-glog-dev \
    libopencv-dev \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init || true && rosdep update

# Clone and build Livox-SDK2
WORKDIR /tmp
RUN git clone https://github.com/Livox-SDK/Livox-SDK2.git \
    && cd Livox-SDK2 \
    && mkdir build && cd build \
    && cmake .. && make -j$(nproc) \
    && make install \
    && ldconfig

# Create workspace
RUN mkdir -p ${WORKSPACE}/src

# Clone livox_ros_driver2
WORKDIR ${WORKSPACE}/src
RUN git clone https://github.com/Livox-SDK/livox_ros_driver2.git

# Clone FAST-LIO
RUN git clone --recursive https://github.com/hku-mars/FAST_LIO.git

# Install FAST-LIO dependencies
RUN apt-get update && apt-get install -y \
    ros-humble-livox-ros-driver2 || true \
    && rm -rf /var/lib/apt/lists/*

# Build workspace
WORKDIR ${WORKSPACE}
RUN . /opt/ros/${ROS_DISTRO}/setup.sh \
    && cd ${WORKSPACE}/src/livox_ros_driver2 \
    && ./build.sh humble

# Build FAST-LIO
RUN . /opt/ros/${ROS_DISTRO}/setup.sh \
    && . ${WORKSPACE}/install/setup.sh \
    && cd ${WORKSPACE} \
    && colcon build --packages-select fast_lio --cmake-args -DCMAKE_BUILD_TYPE=Release

# Copy configuration files
COPY config/ ${WORKSPACE}/config/
COPY launch/ ${WORKSPACE}/launch/

# Set library path
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Setup ROS2 environment on container start
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc \
    && echo "source ${WORKSPACE}/install/setup.bash" >> ~/.bashrc \
    && echo "export ROS_DOMAIN_ID=0" >> ~/.bashrc \
    && echo "export RMW_IMPLEMENTATION=rmw_fastrtps_cpp" >> ~/.bashrc

# Expose ROS2 DDS ports
EXPOSE 7400-7500/udp
EXPOSE 11811/tcp

# Set working directory
WORKDIR ${WORKSPACE}

# Default command
CMD ["/bin/bash"]
