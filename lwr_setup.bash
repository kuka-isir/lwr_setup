#!/usr/bin bash

echo 'Upgrades'
#sudo apt-get update
#sudo apt-get -y upgrade
#sudo apt-get -y dist-upgrade

echo 'OpenSSH'
sudo apt-get install -y openssh-server openssh-client sshfs

echo 'OmniORB'
sudo apt-get install -y omniorb*

echo 'Moveit hack'
sudo apt-get remove -y mongodb mongodb-10gen
sudo apt-get install -y mongodb-clients mongodb-server -o Dpkg::Options::="--force-confdef"

echo 'Htop'
sudo apt-get install -y htop

echo 'NTP'
sudo apt-get install -y ntp
sudo service ntp restart

echo 'Terminator'
sudo apt-get -y install terminator
## Set terminator to default
gconftool --type string --set /desktop/gnome/applications/terminal/exec terminator

echo 'Chrome'
sudo apt-get -y install libxss1 libappindicator1 libindicator7
wget -nc https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome*.deb

echo 'Various IDES'
sudo apt-get -y install qtcreator kdevelop spyder eclipse

echo 'Atom'
wget https://atom.io/download/deb
sudo dpkg -i deb

## ROS Hydro
ROS_DISTRO=indigo
if [ $(lsb_release -cs) == "precise" ]; then ROS_DISTRO=hydro ;fi
if [ $(lsb_release -cs) == "trusty" ]; then ROS_DISTRO=indigo ;fi
if [ $(lsb_release -cs) == "vivid" ]; then ROS_DISTRO=jade ;fi

sudo sh -c "echo 'deb http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main' > /etc/apt/sources.list.d/ros-latest.list"
wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install ros-$ROS_DISTRO-desktop-full ros-$ROS_DISTRO-moveit-* ros-$ROS_DISTRO-ros-control* ros-$ROS_DISTRO-control* python-rosinstall python-pip ros-$ROS_DISTRO-openni* ros-$ROS_DISTRO-gazebo-ros-control

if [ $(lsb_release -cs) == "precise" ]; then sudo apt-get install -y gazebo ;fi
if [ $(lsb_release -cs) == "trusty" ]; then sudo apt-get install -y gazebo2 ;fi

#ROS
source /opt/ros/$ROS_DISTRO/setup.bash
## Rosdep
sudo rosdep init
rosdep update

# OROCOS

toolchain_version=2.8
if [ $ROS_DISTRO == "hydro" ]; then toolchain_version=2.7 ;fi
if [ $ROS_DISTRO == "indigo" ]; then toolchain_version=2.8 ;fi
if [ $ROS_DISTRO == "jade" ]; then toolchain_version=2.8 ;fi


sudo apt-get install -y ros-$ROS_DISTRO-metaruby

mkdir ~/isolated_ws/
cd ~/isolated_ws

rosdep install --from-paths src --ignore-src --rosdistro $ROS_DISTRO -y

git clone --recursive https://github.com/orocos-toolchain/orocos_toolchain.git -b toolchain-$toolchain_version src/orocos/orocos_toolchain
## Get the very latest updates (might be unstable)
git submodule foreach git checkout toolchain-$toolchain_version

# RUBY WORKAROUND
sudo apt-get install -y ruby-configurate
sudo updatedb

config=$(locate config.h | grep ruby)
config_dir=${config%ruby/config.h}

catkin_make_isolated --install -DENABLE_CORBA=ON -DCORBA_IMPLEMENTATION=OMNIORB -DRUBY_CONFIG_INCLUDE_DIR=$config_dir

source install_isolated/setup.sh


##  workspace
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src
catkin_init_workspace

git clone https://github.com/jbohren/rqt_dot.git
git clone https://github.com/jhu-lcsr/rtt_ros_control.git

git clone https://github.com/orocos/rtt_geometry.git
git clone https://github.com/jbohren/conman.git
git clone https://github.com/jbohren/conman.git

git clone https://github.com/orocos/rtt_ros_integration -b $ROS_DISTRO-devel

git clone https://github.com/kuka-isir/rtt_ros_kdl_tools
git clone --recursive https://github.com/kuka-isir/rtt_lwr
git clone https://github.com/kuka-isir/rtt_lwr_controllers
git clone https://github.com/ahoarau/rtt_gazebo

wget https://raw.githubusercontent.com/IDSCETHZurich/re_trajectory-generator/master/kuka_IK/include/friComm.h
mv friComm.h ~/catkin_ws/src/rtt_lwr/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/friComm.h

cd ~/catkin_ws/
rosdep install -r --from-paths ~/catkin_ws/src --ignore-src --rosdistro $ROS_DISTRO -y

sudo apt-get install -qq google-mock lcov
sudo pip install cpp-coveralls --use-mirrors


catkin_make -DCATKIN_ENABLE_TESTING=OFF
echo 'source /home/$USER/catkin_ws/devel/setup.bash' >> ~/.bashrc
source ~/.bashrc
