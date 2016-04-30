#!/usr/bin/env bash

function setBoolean() {
  local v
  if (( $# != 2 )); then
     echo "Err: setBoolean usage" 1>&2; exit 1 ;
  fi

  case "$2" in
    TRUE) v=true ;;
    FALSE) v=false ;;
    *) echo "Err: Unknown boolean value \"$2\"" 1>&2; exit 1 ;;
   esac

   eval $1=$v
}
ros=false
ROS_DISTRO=indigo
orocos=false
orocos29=false
gazebo=false
gazebo_version=""
rtt_lwr=false
rtt_lwr_extras=false
conman=false
ws_path=$HOME/lwr_ws
ws_src=$ws_path/src
ROS_DISTRO=indigo

for i in "$@"
do
case $i in
    --ws_path=*)
    ws_path="${i#*=}"
    shift
    ;;
    --ros=*)
    setBoolean ros "${i#*=}"
    shift
    ;;
    --ros_distro=*)
    ROS_DISTRO="${i#*=}"
    shift
    ;;
    --orocos=*)
    setBoolean orocos="${i#*=}"
    shift
    ;;
    --orocos29=*)
    setBoolean orocos29="${i#*=}"
    shift
    ;;
    --gazebo=*)
    setBoolean gazebo="${i#*=}"
    shift
    ;;
    --gazebo_version=*)
    gazebo_version="${i#*=}"
    shift
    ;;
    --rtt_lwr=*)
    setBoolean rtt_lwr="${i#*=}"
    shift
    ;;
    --rtt_lwr_extras=*)
    setBoolean rtt_lwr_extras="${i#*=}"
    shift
    ;;
    --conman=*)
    setBoolean conman="${i#*=}"
    shift
    ;;
    --default)
    DEFAULT=YES
    shift
    ;;
    *)

    ;;
esac
done

if [[ $ros ]] ; then
    echo "Installing ROS Indigo" $ros
    sudo sh -c "echo 'deb http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main' > /etc/apt/sources.list.d/ros-latest.list"
    wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install -qq -y python-rosdep python-catkin-tools
    sudo apt-get install -qq -y ros-$ROS_DISTRO-catkin python-wstool
    source /opt/ros/$ROS_DISTRO/setup.bash
    sudo rosdep init
    rosdep update
fi

if [[ $orocos ]] ; then
    echo "Installting OROCOS 2.8 from debians"
    sudo apt-get install ros-$ROS_DISTRO-orocos-toolchain ros-$ROS_DISTRO-rtt-*
elif $orocos29 ; then
    echo "Installting OROCOS 2.9 from source"
    mkdir -p $HOME/orocos_ws/src
    cd $HOME/orocos_ws
    catkin init
    catkin config --install
    sudo apt-get install -y git
    cd $HOME/orocos_ws/src
    git clone https://github.com/orocos-toolchain/orocos_toolchain.git --recursive -b toolchain-2.9
    catkin build
    source $HOME/orocos_ws/install/setup.bash
fi

if [[ $gazebo ]]; then
    sudo apt-get install -y ros-$ROS_DISTRO-gazebo$gazebo_version-*
fi

if [[ $rtt_lwr ]]; then
    sudo apt-get install -y curl
    mkdir -p $ws_src
    cd ~/lwr_ws/
    catkin init
    cd ~/lwr_ws/src
    wstool init
    curl https://raw.githubusercontent.com/kuka-isir/rtt_lwr/rtt_lwr-2.0/lwr_utils/config/rtt_lwr.rosinstall | wstool merge -

    if [[ $rtt_lwr_extras ]]; then
        curl https://raw.githubusercontent.com/kuka-isir/rtt_lwr/rtt_lwr-2.0/lwr_utils/config/rtt_lwr_extras.rosinstall | wstool merge -
    fi

    if [[ $conman ]]; then
        curl https://raw.githubusercontent.com/kuka-isir/rtt_lwr/rtt_lwr-2.0/lwr_utils/config/conman.rosinstall | wstool merge -
    fi

    wstool update -j$(nproc)
    rosrun rtt_roscomm create_rtt_msgs control_msgs
    rosrun rtt_roscomm create_rtt_msgs controller_manager_msgs
    curl https://raw.githubusercontent.com/IDSCETHZurich/re_trajectory-generator/master/kuka_IK/include/friComm.h >> $ws_src/rtt_lwr/lwr_hardware/kuka_lwr_fri/include/kuka_lwr_fri/friComm.h
    rosdep install -r --from-paths $ws_src/ --rosdistro $ROS_DISTRO -y
    catkin build
    source $ws_path/devel/setup.bash
fi
