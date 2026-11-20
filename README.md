# CubicDoggo 14A: Homemade 12-DOF 4-Legged Robot Recipe with 6-DOF Arm
Cubic Doggo 14A Googboi is based on [Cubic Doggo 07B Wouf](https://github.com/SphericalCowww/CubicDoggo_07B), incorporating an [SO-101 arm](https://huggingface.co/docs/lerobot/en/so101). The robot is the simplest Cubic Doggo built for the [Tag of Flag](https://github.com/SphericalCowww/tag_of_flag) game.

## Running SO-101 arms

### Initializing SO-101 with LeRobot services

Note that for this setup, the leader arms are assumed to use virtual servos, such as STS3215-C066 (or WaveShare ST3215 (SE)) that have 7.2 V grading (powered by a 5 V supply). 

The servo IDs are 6-1 from top to bottom. Remember to always put on the PLA holder for servo 5 and connect both wires before any other part, as the wires will otherwise be extremely difficult to access afterwards. Then install the arms following [HuggingFace](https://huggingface.co/docs/lerobot/en/so101).

Plug the driver board into the Raspberry Pi:

    sudo dmesg | tail -30
    ls -l /dev/ttyACM*                      # or whatever connection is found
    sudo usermod -aG dialout $USER
    sudo reboot

Install,

    sudo apt install python3.12-venv libevdev-dev ffmpeg

Set up the Python environment to install [LeRobot](https://github.com/huggingface/lerobot),

    cd CubicDoggo_14A/
    cd ..
    python3 -m venv CubicDoggo_14A_env
    source CubicDoggo_14A_env/bin/activate
    pip install --upgrade pip jinja2 pyyaml typeguard setuptools wheel
    git clone https://github.com/huggingface/lerobot.git
    cd lerobot
    pip install -e .
    pip install -e ".[feetech]"

Follow the calibration steps for the follower (see also [YouTube](https://www.youtube.com/watch?v=Nhfda8h7e2I)),

    # plug in the driver board
    lerobot-find-port
    # unplug the driver board
    ## The port of this MotorsBus is '/dev/ttyACM0'
    # plug in the driver board
    ls -l /dev/serial/by-id/
    ## ... usb-1a86_USB_Single_Serial_5B8E112477-if00 -> ../../ttyACM0
    lerobot-setup-motors --robot.type=so101_follower --robot.port=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5B8E112477-if00
    # Connecting the servos from top to bottom independently to the driver board one-by-one, following the instructions
    ## ... 'shoulder_pan' motor id set to 1
    # After completion, connect all servos in a daisy chain 
    lerobot-calibrate --robot.type=so101_follower --robot.port=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5B8E112477-if00 --robot.id=my_follower
    # Follow the instructions

For the leader, while 5V is completely sufficient for operation, calibration sometimes needs higher voltage,

    ls -l /dev/serial/by-id/
    ## ... usb-1a86_USB_Single_Serial_5C93152513-if00 -> ../../ttyACM0
    lerobot-setup-motors --teleop.type=so101_leader --teleop.port=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5C93152513-if00
    # ...
    lerobot-calibrate --teleop.type=so101_leader --teleop.port=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5C93152513-if00 --teleop.id=my_leader

Once everything is done,

    deactivate

### Running SO-101 on ROS

Note that although it is not needed in this setup, ``so101_ros2`` does require Gazebo, so don't forget to install it,

    cd CubicDoggo_14A/
    cd ..
    source CubicDoggo_14A_env/bin/activate
    export CMAKE_PREFIX_PATH="/opt/ros/jazzy/opt/gz_msgs_vendor:$CMAKE_PREFIX_PATH"
    export CMAKE_PREFIX_PATH="/opt/ros/jazzy/opt/gz_msgs_vendor:/opt/ros/jazzy/opt/gz_transport_vendor:$CMAKE_PREFIX_PATH"
    pip install catkin_pkg 
    mkdir so101_ros2
    cd so101_ros2
    git clone https://github.com/adoodevv/so101_ros2.git
    mv so101_ros2 src
    cp ../CubicDoggo_14A/so101_ros2/src/so101_bringup/launch/so101_real_moveit_2devices.launch.py src/so101_bringup/launch/
    sudo rosdep init
    rosdep update
    rosdep install --from-paths src --ignore-src -r -y
    colcon build --symlink-install
    source install/setup.bash

The following is for debugging on a Raspberry Pi 4 with 1 Gb of RAM

    export CMAKE_PREFIX_PATH="/opt/ros/jazzy/opt/gz_msgs_vendor:$CMAKE_PREFIX_PATH"
    export CMAKE_PREFIX_PATH="/opt/ros/jazzy/opt/gz_msgs_vendor:/opt/ros/jazzy/opt/gz_transport_vendor:$CMAKE_PREFIX_PATH"
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    free -h                 # check if 4 Gb more RAM
    CMAKE_BUILD_PARALLEL_LEVEL=1 MAKEFLAGS="-j1" colcon build --symlink-install --executor sequential --event-handlers console_direct+ status-
    source install/setup.bash

Connect both driver boards and test out the calibration files, 

    ros2 run so101_hardware so101_hardware_check --port /dev/serial/by-id/usb-1a86_USB_Single_Serial_5B8E112477-if00 --calibration ~/.cache/huggingface/lerobot/calibration/robots/so_follower/my_follower.json
    ros2 run so101_hardware so101_hardware_check --port /dev/serial/by-id/usb-1a86_USB_Single_Serial_5C93152513-if00 --calibration ~/.cache/huggingface/lerobot/calibration/teleoperators/so_leader/my_leader.json

Then launch the arms,

    # For no torque with rViz
    ros2 launch so101_bringup so101_real_moveit.launch.py port:=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5B8E112477-if00 read_only:=true
    # For powered without rViz
    ros2 launch so101_bringup so101_real_moveit.launch.py port:=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5B8E112477-if00 use_rviz:=false 
    # For teleop
    ros2 launch so101_bringup so101_teleop.launch.py port:=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5B8E112477-if00 leader_port:=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5C93152513-if00 use_rviz:=false 

Note that if the arm has trouble connecting all servos, try turning down the communication to 50 Hz,

    vim src/so101_moveit_config/config/so101/ros2_controllers.yaml
    # update_rate: 50
    colcon build

### Running SO-101 on ROS with leader and follower on separate devices

On both devices, add,
    
    vim ~/.bashrc
    # export ROS_DOMAIN_ID=141
    source ~/.bashrc

Test discovery, as long as they are on the same network,

    sudo apt install ros-jazzy-demo-nodes-cpp
    # on leader device
    ros2 run demo_nodes_cpp talker
    # on follower device
    ros2 run demo_nodes_cpp listener

On both devices,

    cd CubicDoggo_14A
    cp ../CubicDoggo_14A/so101_ros2/src/so101_bringup/launch/so101_real_moveit_2devices.launch.py ../so101_ros2/src/so101_bringup/launch/so101_real_moveit_2devices.launch.py
    cd ../so101_ros2
    colcon build

Then, to run the teleoperation,

    # on leader device
    ros2 launch so101_bringup so101_real_moveit_2devices.launch.py leader_only:=true leader_port:=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5C93152513-if00 leader_id:=my_leader use_rviz:=false 
    # on follower device
    ros2 node list
    ros2 launch so101_bringup so101_real_moveit_2devices.launch.py teleop:=true port:=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5B8E112477-if00 follower_id:=my_follower use_rviz:=false 

Check if the domain is properly followed; do either of the following while running the code:

    sudo cat /proc/$(pgrep -f '/joy/joy_node' | head -n 1)/environ | tr '\0' '\n' | grep -E 'ROS_DOMAIN_ID|ROS_AUTOMATIC_DISCOVERY_RANGE'
    sudo cat /proc/$(pgrep -f '/so101_hardware/so101_leader' | head -n 1)/environ | tr '\0' '\n' | grep -E 'ROS_DOMAIN_ID|ROS_AUTOMATIC_DISCOVERY_RANGE'

### Bluetooth setup

    sudo apt install bluez bluez-tools network-manager
    sudo systemctl enable --now bluetooth
    bluetoothctl show
    
Then create a Bluetooth PAN connection on the follower side:

    nmcli --version
    ip -br addr
    sudo nmcli connection add type bluetooth con-name cubicggoogboi-server ifname btnap0 bluetooth.type nap ipv4.method shared ipv6.method disabled
    sudo nmcli connection up cubicgoogboi-server
    # sudo nmcli connection down cubicgoogboi-server                                  # if needed
    # sudo systemctl restart NetworkManager                                        # if needed
    # nmcli device status
    ip -br addr
    bluetoothctl show | grep -i "NAP"
    # UUID: NAP                       (00001116-0000-1000-8000-00805f9b34fb)

Then create a Bluetooth PAN connection on the leader side:

    nmcli --version
    ip -br addr
    sudo nmcli connection add type bluetooth con-name cubicgoogboi-client ifname "*" bluetooth.type panu bluetooth.bdaddr 88:A2:9E:C2:0B:A0 ipv4.method auto ipv6.method disabled
    sudo nmcli connection up cubicgoogboi-client
    # sudo nmcli connection down cubicgoogboi-client                                  # if needed
    # sudo systemctl restart NetworkManager                                        # if needed
    # nmcli device status
    ip -br addr
    ping -c 4 10.42.0.1
    bluetoothctl show
    bluetoothctl info 88:A2:9E:C2:0B:A0
    sudo sdptool browse 88:A2:9E:C2:0B:A0 | grep -i -A 10 "Network Access"         # need to find some lines
    
To start pairing, on the follower device,

    bluetoothctl
    power on
    agent on
    default-agent
    discoverable on
    pairable on
    # do not exit

Then, on the leader device, 

    bluetoothctl
    power on
    agent on
    default-agent
    scan on
    # Pair immediately after seeing
    # [bluetooth]# [NEW] Device 88:A2:9E:C2:0B:A0 cubicgoogboi-desktop
    pair 88:A2:9E:C2:0B:A0
    # yes
    trust 88:A2:9E:C2:0B:A0
    connect 88:A2:9E:C2:0B:A0
    # yes on the follower side
    exit                          # on both sides 
    # For debugging:
    ## bluetoothctl info 88:A2:9E:C2:0B:A0                       
    ## sudo journalctl -u bluetooth -n 80 --no-pager   

To automatically start the connection, on follower device:

    sudo nmcli connection modify cubicgoogboi-server connection.autoconnect yes
    nmcli -f NAME,AUTOCONNECT connection show

And on the leader device:

    sudo nmcli connection modify cubicgoogboi-client connection.autoconnect yes
    nmcli -f NAME,AUTOCONNECT connection show

To confirm connections, on the follower device:

    nmcli device status
    ip -br addr | grep btnap0
    # sudo nmcli connection up cubicgoogboi-server          # if not up

And on the leader device:

    nmcli device status
    ip -br addr | grep bnep0
    # sudo nmcli connection up cubicgoogboi-client          # if not up
    ping -c 4 10.42.0.1

## References:

- Trushant Adeshara, SO101 Arms: Calibration and Motor Configuration
 (<a href="https://www.youtube.com/watch?v=Nhfda8h7e2I">YouTube</a>)
- TheRobotStudio, SO-101 STL files, (<a href="https://github.com/TheRobotStudio/SO-ARM100/tree/main/STL/SO101/Individual">GitHub</a>)

## Acknowledgements

- SO-101 arm hardware kit purchased from [Waveshare](https://www.waveshare.com/wiki/SO-ARM100/101_Kit_Aassembly). Original hardware design by TheRobotStudio ([GitHub](https://github.com/TheRobotStudio/SO-ARM100)) under [Apache-2.0 license](https://github.com/TheRobotStudio/SO-ARM100/blob/main/LICENSE)
- SO-101 arm software package follows LeRobot [GitHub](https://github.com/huggingface/lerobot) under [Apache-2.0 license](https://github.com/huggingface/lerobot/blob/main/LICENSE)
- SO-101 ROS2 Jazzy control forked from adoodevv [GitHub](https://github.com/adoodevv/so101_ros2) under [BSD-3-Clause license](https://github.com/adoodevv/so101_ros2/blob/main/LICENSE)
- Libraries and some examples borrowed from Waveshare: https://www.waveshare.com/wiki/Bus_Servo_Adapter_(A). The license is not specified. For reference only


