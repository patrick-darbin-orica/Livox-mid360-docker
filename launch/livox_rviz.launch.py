#!/usr/bin/env python3

"""
Livox Mid-360 with RViz2 visualization launch file
Launches the LiDAR driver with RViz2 for real-time visualization
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
            'xfer_format': 1,
            'multi_topic': 0,
            'data_src': 0,
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

    # RViz2 node with basic configuration
    rviz2 = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        output='screen',
        arguments=['-d', '/root/livox_ws/config/livox_rviz.rviz'] if os.path.exists('/root/livox_ws/config/livox_rviz.rviz') else []
    )

    # Static transform publisher (livox_frame to base_link)
    static_tf = Node(
        package='tf2_ros',
        executable='static_transform_publisher',
        name='livox_tf_publisher',
        arguments=['0', '0', '0', '0', '0', '0', 'base_link', 'livox_frame']
    )

    return LaunchDescription([
        config_file_arg,
        livox_driver,
        static_tf,
        rviz2
    ])
