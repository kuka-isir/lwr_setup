# LWR Setup from scratch

[![Build Status](https://travis-ci.org/kuka-isir/lwr_setup.svg?branch=master)](https://travis-ci.org/kuka-isir/lwr_setup)

##### Get latest updates
```bash
sudo apt-get update
sudo apt-get -y upgrade
```
##### Get some useful tools
```bash
 echo 'OpenSSH'
 sudo apt-get install -y openssh-server openssh-client sshfs

 echo 'NTP'
 sudo apt-get install -y ntp
 sudo service ntp restart

 echo 'Terminator'
 sudo apt-get -y install terminator

 echo 'Various IDES'
 sudo apt-get -y install qtcreator kdevelop spyder vim
```
##### Installation script
```bash
wget https://raw.githubusercontent.com/kuka-isir/lwr_setup/2.0/lwr_setup.bash
bash lwr_setup.bash
# Come back in 20min
```

##### Update your bashrc
```bash
echo 'source ~/lwr_ws/devel/setup.bash' >> .bashrc
```
