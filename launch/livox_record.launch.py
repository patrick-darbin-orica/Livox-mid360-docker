#!/usr/bin/env python3

"""
Livox Mid-360 data recording launch file
Launches the LiDAR driver and records data to rosbag2 format
"""

from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument, ExecuteProcess
from launch.substitutions import LaunchConfiguration
from datetime import datetime
import os

def generate_launch_description():

    # Generate timestamp for bag file
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    default_bag_path = f'/root/livox_ws/data/livox_mid360_{timestamp}'

    # Declare arguments
    config_file_arg = DeclareLaunchArgument(
        'config_file',
        default_value='/root/livox_ws/config/MID360_config.json',
        description='Path to Livox configuration JSON file'
    )

    bag_path_arg = DeclareLaunchArgument(
        'bag_path',
        default_value=default_bag_path,
        description='Path to save rosbag2 recording'
    )

    topics_arg = DeclareLaunchArgument(
        'topics',
        default_value='/livox/pointcloud /livox/imu',
        description='Topics to record (space-separated)'
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

    # ROS2 bag recorder
    bag_recorder = ExecuteProcess(
        cmd=['ros2', 'bag', 'record', '-o', LaunchConfiguration('bag_path'),
             '/livox/pointcloud', '/livox/imu', '/tf', '/tf_static'],
        output='screen',
        shell=False
    )

    # Optional: Display recording status
    status_node = Node(
        package='rqt_topic',
        executable='rqt_topic',
        name='topic_monitor',
        output='screen',
        condition=None  # Can be conditional based on user preference
    )

    return LaunchDescription([
        config_file_arg,
        bag_path_arg,
        topics_arg,
        livox_driver,
        bag_recorder
    ])
