#!/usr/bin/env bash


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

if [ ! -n "$TRAVIS" ];then
	sudo apt-get install -y -qq ros-$ROS_DISTRO-rtt ros-$ROS_DISTRO-rtt-*
fi

#ROS
source /opt/ros/$ROS_DISTRO/setup.bash
## Rosdep
sudo rosdep init
rosdep update

ROS_WS=/home/$USER

LWR_WS=$ROS_WS/lwr_ws

mkdir -p $LWR_WS/src

cd $LWR_WS/src

git clone https://github.com/jbohren/rqt_dot.git
git clone https://github.com/jhu-lcsr/rtt_ros_control.git
git clone https://github.com/jbohren/conman.git

if [ -n "$XENOMAI" ]; then
	git clone https://github.com/orocos/rtt_geometry.git
	git clone https://github.com/orocos/rtt_ros_integration -b $ROS_DISTRO-devel

	# OROCOS from sources
	toolchain_version=2.8
	if [ $ROS_DISTRO == "hydro" ]; then toolchain_version=2.7 ;fi
	if [ $ROS_DISTRO == "indigo" ]; then toolchain_version=2.8 ;fi
	if [ $ROS_DISTRO == "jade" ]; then toolchain_version=2.8 ;fi

	git clone --recursive https://github.com/orocos-toolchain/orocos_toolchain.git -b toolchain-$toolchain_version
	cd orocos_toolchain
	git submodule foreach git pull
	git submodule foreach git checkout toolchain-$toolchain_version
fi


cd $LWR_WS
catkin init

cd $LWR_WS/src
wstool init
## Get the installation script
curl https://raw.githubusercontent.com/kuka-isir/rtt_lwr/master/lwr_scripts/scripts/.rosinstall | wstool merge -
## Download source
if [ -n "$TRAVIS" ];then
	wstool update -j2
else
	wstool update -j$(nproc)
fi

curl https://raw.githubusercontent.com/IDSCETHZurich/re_trajectory-generator/master/kuka_IK/include/friComm.h >> $LWR_WS/src/rtt_lwr/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/friComm.h

cd $LWR_WS
catkin init
## Warning this installs gazebo 2 (default in ros indigo, so please run this before installing gazebo 6 (below))
rosdep install -r --from-paths $LWR_WS/ --rosdistro $ROS_DISTRO -y


######### INSTALL GAZEBO 6 ###############################################
sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
sudo apt-get update

sudo apt-get -y install libsdformat3 sdformat-sdf
sudo apt-get -y install gazebo6
# For developers that work on top of Gazebo, one extra package
sudo apt-get -y install libgazebo6-dev
sudo apt-get -y install ros-$ROS_DISTRO-gazebo6-*
#########################################################################

if [ -n "$TRAVIS" ]; then 
    cd $LWR_WS/src
    catkin build --limit-status-rate 0.1 --no-notify --no-status -j2 -DCATKIN_ENABLE_TESTING=OFF -DCMAKE_BUILD_TYPE=Debug
    source ../devel/setup.sh
else
    cd $LWR_WS/src
    catkin build
    source ../devel/setup.sh
fi
