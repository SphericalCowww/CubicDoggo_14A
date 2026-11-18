#!/bin/bash
source /opt/ros/jazzy/setup.bash
source /home/cubicgoogboi/Documents/CubicDoggo_14A/install/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export QT_QPA_PLATFORM=xcb

export ROS_DOMAIN_ID=141         # to prevent controller interference

exec ros2 launch my_robot_bringup cubic_doggo.with_lifecycle.launch.py




