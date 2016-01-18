#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y -qq curl

## ROS 
ROS_DISTRO=indigo
if [ $(lsb_release -cs) == "precise" ]; then ROS_DISTRO=hydro ;fi
if [ $(lsb_release -cs) == "trusty" ]; then ROS_DISTRO=indigo ;fi
if [ $(lsb_release -cs) == "vivid" ]; then ROS_DISTRO=jade ;fi

sudo sh -c "echo 'deb http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main' > /etc/apt/sources.list.d/ros-latest.list"
wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
sudo apt-get update
sudo apt-get install -qq -y python-rosdep python-catkin-tools
sudo apt-get install -qq -y ros-$ROS_DISTRO-catkin python-wstool

#ROS
source /opt/ros/$ROS_DISTRO/setup.bash
## Rosdep
sudo rosdep init
rosdep update


##### Creating user directories
if [ ! -n "$ROS_WS" ]; then
ROS_WS=/home/$USER
fi

if [ ! -n "$LWR_WS" ]; then
LWR_WS=$ROS_WS/lwr_ws
fi

mkdir -p $LWR_WS/src
#################################

cd $LWR_WS/src

cd $LWR_WS
catkin init

# This is necessary for the mqueue transport 
catkin install

cd $LWR_WS/src
wstool init
## Get the installation script
curl https://raw.githubusercontent.com/kuka-isir/rtt_lwr/master/lwr_scripts/config/rtt_lwr.rosinstall | wstool merge -

if [ -n "$RTT_LWR_EXTRAS" ]; then
	curl https://raw.githubusercontent.com/kuka-isir/rtt_lwr/master/lwr_scripts/config/rtt_lwr_extras.rosinstall | wstool merg$
fi

## Download source
if [ -n "$TRAVIS" ];then
	wstool update -j2
else
	wstool update -j$(nproc)
fi

curl https://raw.githubusercontent.com/IDSCETHZurich/re_trajectory-generator/master/kuka_IK/include/friComm.h >> $LWR_WS/src/rtt_lwr/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/friComm.h

## Warning this installs gazebo 2 (default in ros indigo, so please run this before installing gazebo 6 (below))
rosdep install -r --from-paths $LWR_WS/ --rosdistro $ROS_DISTRO -y


######### INSTALL GAZEBO 6 ###############################################
if [ -n "$GAZEBO6" ]; then
sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
sudo apt-get update

sudo apt-get -y install libsdformat3 sdformat-sdf
sudo apt-get -y install gazebo6
# For developers that work on top of Gazebo, one extra package
sudo apt-get -y install libgazebo6-dev
sudo apt-get -y install ros-$ROS_DISTRO-gazebo6-*
fi
#########################################################################



# Build everything
cd $LWR_WS/src
if [ -n "$TRAVIS" ]; then 
    catkin build --limit-status-rate 0.1 --no-notify --no-status -j2 -DCATKIN_ENABLE_TESTING=OFF -DCMAKE_BUILD_TYPE=Debug
else
    catkin build -DCATKIN_ENABLE_TESTING=OFF -DCMAKE_BUILD_TYPE=Release
fi
source $LWR_WS/install/setup.sh
