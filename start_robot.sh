#!/bin/bash
source /opt/ros/jazzy/setup.bash
source /home/cubicgoogboi/Documents/CubicDoggo_14A/install/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export QT_QPA_PLATFORM=xcb

export ROS_DOMAIN_ID=141
export ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET

ros2 launch so101_bringup so101_real_moveit_2devices.launch.py teleop:=true port:=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5B8E112477-if00 follower_id:=my_follower use_rviz:=false &
SO101_PID=$!
sleep 5
ros2 launch my_robot_bringup cubic_doggo.with_lifecycle.launch.py &
DOGGO_PID=$!
wait

# exec ros2 launch so101_bringup so101_real_moveit_2devices.launch.py leader_only:=true leader_port:=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5B90152131-if00 leader_id:=my_leader use_rviz:=false 



