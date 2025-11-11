#!/usr/bin/env python3

"""
Basic Livox Mid-360 driver launch file
Launches only the LiDAR driver without visualization
"""

from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
import os

def generate_launch_description():

    # Declare arguments
    config_file_arg = DeclareLaunchArgument(
        'config_file',
        default_value='/root/livox_ws/config/MID360_config.json',
        description='Path to Livox configuration JSON file'
    )

    # Livox driver node
    livox_driver = Node(
        package='livox_ros_driver2',
        executable='livox_ros_driver2_node',
        name='livox_lidar',
        output='screen',
        parameters=[{
            'user_config_path': LaunchConfiguration('config_file'),
            'xfer_format': 1,  # 0-Pointcloud2(PointXYZRTLT), 1-customized pointcloud format
            'multi_topic': 0,  # 0-All LiDARs share one topic, 1-One LiDAR one topic
            'data_src': 0,     # 0-lidar, 1-hub
            'publish_freq': 10.0,
            'output_data_type': 0,
            'frame_id': 'livox_frame',
            'lidar_bag': '',
            'cmdline_bd_code': 'livox0000000001'
        }],
        remappings=[
            ('/livox/lidar', '/livox/pointcloud'),
            ('/livox/imu', '/livox/imu')
        ]
    )

    return LaunchDescription([
        config_file_arg,
        livox_driver
    ])
