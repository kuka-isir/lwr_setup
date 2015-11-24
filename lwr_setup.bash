#!/usr/bin bash

if [ ! -n "$TRAVIS" ]; then
 echo 'Upgrades'
 sudo apt-get update
 sudo apt-get -y upgrade
 sudo apt-get -y dist-upgrade
fi

if [ ! -n "$TRAVIS" ]; then
 echo 'OpenSSH'
 sudo apt-get install -y openssh-server openssh-client sshfs
fi

if [ ! -n "$TRAVIS" ]; then
 echo 'Htop'
 sudo apt-get install -y htop

 echo 'NTP'
 sudo apt-get install -y ntp
 sudo service ntp restart

 echo 'Terminator'
 sudo apt-get -y install terminator

 echo 'Chrome'
 sudo apt-get -y install libxss1 libappindicator1 libindicator7
 wget -nc https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
 sudo dpkg -i google-chrome*.deb

 echo 'Various IDES'
 sudo apt-get -y install qtcreator kdevelop spyder eclipse vim

 echo 'Atom'
 wget https://atom.io/download/deb
 sudo dpkg -i deb

 echo 'Resolving issues'
 sudo apt-get -f -y install
fi

## ROS 
ROS_DISTRO=indigo
if [ $(lsb_release -cs) == "precise" ]; then ROS_DISTRO=hydro ;fi
if [ $(lsb_release -cs) == "trusty" ]; then ROS_DISTRO=indigo ;fi
if [ $(lsb_release -cs) == "vivid" ]; then ROS_DISTRO=jade ;fi

sudo sh -c "echo 'deb http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main' > /etc/apt/sources.list.d/ros-latest.list"
wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
sudo apt-get update
sudo apt-get install -qq -y python-rosdep python-catkin-tools
sudo apt-get install -qq -y ros-$ROS_DISTRO-catkin ros-$ROS_DISTRO-ros

#ROS
source /opt/ros/$ROS_DISTRO/setup.bash
## Rosdep
sudo rosdep init
rosdep update

ROS_WS=~/ros_ws

LWR_WS=$ROS_WS/lwr_ws
LWR_CONTROLLERS_WS=$ROS_WS/lwr_controllers_ws
EXT_WS=$ROS_WS/ext_ws

mkdir -p $LWR_WS/src
mkdir -p $LWR_CONTROLLERS_WS/src
mkdir -p $EXT_WS/src

cd $EXT_WS/src

git clone https://github.com/jbohren/rqt_dot.git
git clone https://github.com/jhu-lcsr/rtt_ros_control.git
git clone https://github.com/jbohren/conman.git

if [ -n "$XENOMAI" ]; then
git clone https://github.com/orocos/rtt_geometry.git
git clone https://github.com/orocos/rtt_ros_integration -b $ROS_DISTRO-devel
fi

cd $LWR_WS/src

git clone https://github.com/kuka-isir/rtt_ros_kdl_tools
git clone --recursive https://github.com/kuka-isir/rtt_lwr

wget https://raw.githubusercontent.com/IDSCETHZurich/re_trajectory-generator/master/kuka_IK/include/friComm.h
mv friComm.h $LWR_WS/src/rtt_lwr/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/friComm.h

git clone https://github.com/kuka-isir/lwr_project_creator
git clone https://github.com/ahoarau/rtt_gazebo
git clone https://github.com/kuka-isir/lwr_project_creator.git

cd $LWR_CONTROLLERS_WS/src

git clone https://github.com/kuka-isir/rtt_lwr_controllers


cd $EXT_WS
catkin init
rosdep install -r --from-paths $EXT_WS/ --rosdistro $ROS_DISTRO -y


cd $LWR_WS
catkin init
rosdep install -r --from-paths $LWR_WS/ --rosdistro $ROS_DISTRO -y


cd $LWR_CONTROLLERS_WS
catkin init
rosdep install -r --from-paths $LWR_CONTROLLERS_WS/ --rosdistro $ROS_DISTRO -y


cd $EXT_WS/src
catkin build --limit-status-rate 0.1 --no-notify -j2 -DCATKIN_ENABLE_TESTING=OFF -DCMAKE_BUILD_TYPE=Debug
source ../devel/setup.sh

cd $LWR_WS/src
catkin build --limit-status-rate 0.1 --no-notify -j2 -DCATKIN_ENABLE_TESTING=OFF -DCMAKE_BUILD_TYPE=Debug
source ../devel/setup.sh

cd $LWR_CONTROLLERS_WS/src
catkin build --limit-status-rate 0.1 --no-notify -j2 -DCATKIN_ENABLE_TESTING=OFF -DCMAKE_BUILD_TYPE=Debug
source ../devel/setup.sh



####################################### INSTALL GAZEBO 6
sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
sudo apt-get update

sudo apt-get -y install libsdformat3 sdformat-sdf
sudo apt-get -y install gazebo6
# For developers that work on top of Gazebo, one extra package
sudo apt-get -y install libgazebo6-dev
sudo apt-get -y install ros-$ROS_DISTRO-gazebo6-*

cd $EXT_WS
catkin build -v


cd $LWR_WS
catkin build -v


cd $LWR_CONTROLLERS_WS
catkin build -v
