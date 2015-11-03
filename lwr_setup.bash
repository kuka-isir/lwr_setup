#!/usr/bin bash

if [ ! -n "$TRAVIS" ]; then
 echo 'Upgrades'
 sudo apt-get update
 sudo apt-get -y upgrade
 sudo apt-get -y dist-upgrade
;fi

if [ ! -n "$TRAVIS" ]; then
 echo 'OpenSSH'
 sudo apt-get install -y openssh-server openssh-client sshfs
;fi

if [ -n "$TRAVIS" ]; then
echo 'OmniORB'
sudo apt-get install -y omniorb*

echo 'Moveit hack'
sudo apt-get remove -y mongodb mongodb-10gen
sudo apt-get install -y mongodb-clients mongodb-server -o Dpkg::Options::="--force-confdef"
;fi

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
fi;

## ROS 
ROS_DISTRO=indigo
if [ $(lsb_release -cs) == "precise" ]; then ROS_DISTRO=hydro ;fi
if [ $(lsb_release -cs) == "trusty" ]; then ROS_DISTRO=indigo ;fi
if [ $(lsb_release -cs) == "vivid" ]; then ROS_DISTRO=jade ;fi

sudo sh -c "echo 'deb http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main' > /etc/apt/sources.list.d/ros-latest.list"
wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install ros-$ROS_DISTRO-desktop-full 
sudo apt-get -y install ros-$ROS_DISTRO-moveit-* 
sudo apt-get -y install ros-$ROS_DISTRO-ros-control* 
sudo apt-get -y install ros-$ROS_DISTRO-control* 
sudo apt-get -y install python-rosinstall python-pip 
sudo apt-get -y install ros-$ROS_DISTRO-openni* 
sudo apt-get -y install ros-$ROS_DISTRO-gazebo*
sudo apt-get -y install ros-$ROS_DISTRO-metaruby

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

if [ -n "$XENOMAI" ]; then

echo 'OROCOS INSTALLATION'
echo 'FOLLOW XENOMAI INSTALLATION FIRST'

OROCOS_WS=$ROS_WS/orocos_ws
mkdir -p $OROCOS_WS/src
cd $OROCOS_WS/srcgit clone https://github.com/jbohren/conman.git

# OROCOS from sources
toolchain_version=2.8
if [ $ROS_DISTRO == "hydro" ]; then toolchain_version=2.7 ;fi
if [ $ROS_DISTRO == "indigo" ]; then toolchain_version=2.8 ;fi
if [ $ROS_DISTRO ==git clone https://github.com/jbohren/conman.git "jade" ]; then toolchain_version=2.8 ;fi

git clone --recursive https://github.com/orocos-toolchain/orocos_toolchain.git -b toolchain-$toolchain_version src/orocos/orocos_toolchain
## Get the very last updates (might be unstable)
git submodule foreach git pull
git submodule foreach git checkout toolchain-$toolchain_version

# RUBY WORKAROUND
sudo apt-get install -y ruby-configurate
sudo updatedb

config=$(locate ruby | grep /usr/ | grep /config.h)
echo "CONFIG RUBY : $config"
config_dir=${config%ruby/config.h}
echo "CONFIG RUBY DIR : $config_dir"

catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DRUBY_CONFIG_INCLUDE_DIR=$config_dir

source $OROCOS_WS/install_isolated/setup.sh

;fi

cd $EXT_WS/src
catkin_init_workspace

git clone https://github.com/jbohren/rqt_dot.git
git clone https://github.com/jhu-lcsr/rtt_ros_control.git
git clone https://github.com/jbohren/conman.git

if [ -n "$XENOMAI" ]; then
git clone https://github.com/orocos/rtt_geometry.git
git clone https://github.com/orocos/rtt_ros_integration -b $ROS_DISTRO-devel
fi;

cd $LWR_WS/src
catkin_init_workspace

git clone https://github.com/kuka-isir/rtt_ros_kdl_tools
git clone --recursive https://github.com/kuka-isir/rtt_lwr

wget https://raw.githubusercontent.com/IDSCETHZurich/re_trajectory-generator/master/kuka_IK/include/friComm.h
mv friComm.h $LWR_WS/src/rtt_lwr/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/friComm.h

git clone https://github.com/kuka-isir/lwr_project_creator
git clone https://github.com/ahoarau/rtt_gazebo

cd $LWR_CONTROLLERS_WS/src
catkin_init_workspace

git clone https://github.com/kuka-isir/rtt_lwr_controllers


echo 'COMPILING'

cd $EXT_WS
catkin_make -DCATKIN_ENABLE_TESTING=OFF
source devel/setup.sh

cd $LWR_WS
catkin_make
source devel/setup.sh

cd $LWR_CONTROLLERS_WS
catkin_make
source devel/setup.sh

echo 'source $LWR_CONTROLLERS_WS/devel/setup.bash' >> ~/.bashrc
source ~/.bashrc
