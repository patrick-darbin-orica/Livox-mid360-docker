#!/usr/bin/env python3

"""
Livox Mid-360 with FAST-LIO SLAM launch file
Launches the LiDAR driver with FAST-LIO for real-time SLAM
"""

from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument, ExecuteProcess
from launch.substitutions import LaunchConfiguration
import os

def generate_launch_description():

    # Declare arguments
    config_file_arg = DeclareLaunchArgument(
        'config_file',
        default_value='/root/livox_ws/config/MID360_config.json',
        description='Path to Livox configuration JSON file'
    )

    fastlio_config_arg = DeclareLaunchArgument(
        'fastlio_config',
        default_value='/root/livox_ws/config/fastlio_mid360.yaml',
        description='Path to FAST-LIO configuration YAML file'
    )

    # Livox driver node
    livox_driver = Node(
        package='livox_ros_driver2',
        executable='livox_ros_driver2_node',
        name='livox_lidar',
        output='screen',
        parameters=[{
            'user_config_path': LaunchConfiguration('config_file'),
            'xfer_format': 0,
            'multi_topic': 0,
            'data_src': 0,
            'publish_freq': 10.0,
            'output_data_type': 0,
            'frame_id': 'livox_frame',
            'lidar_bag': '',
            'cmdline_bd_code': 'livox0000000001'
        }]
    )

    # FAST-LIO node
    fast_lio = Node(
        package='fast_lio',
        executable='fastlio_mapping',
        name='fast_lio',
        output='screen',
        parameters=[LaunchConfiguration('fastlio_config')],
        remappings=[
            ('/cloud_registered', '/fast_lio/cloud_registered'),
            ('/Odometry', '/fast_lio/odometry'),
            ('/path', '/fast_lio/path')
        ]
    )

    # RViz2 with FAST-LIO visualization
    rviz2 = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        output='screen',
        arguments=['-d', '/root/livox_ws/config/fastlio_rviz.rviz'] if os.path.exists('/root/livox_ws/config/fastlio_rviz.rviz') else []
    )

    return LaunchDescription([
        config_file_arg,
        fastlio_config_arg,
        livox_driver,
        fast_lio,
        rviz2
    ])
