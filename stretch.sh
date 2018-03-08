#!/bin/bash

sudo apt-get update -y
sudo apt-get upgrade -y
# rpi-update # Update Pi Firmware - Should be covered by above commands

echo "Europe/London" | sudo tee /etc/timezone
sudo cp /usr/share/zoneinfo/Europe/London /etc/localtime

# Install .NET Core (future proofing)
sudo apt-get install libunwind8 libunwind8-dev gettext libicu-dev liblttng-ust-dev libcurl4-openssl-dev libssl-dev uuid-dev -y
wget https://github.com/dotnet/core-setup/files/716356/dotnet-ubuntu.16.04-arm.1.2.0-beta-001291-00.tar.gz
mkdir ~/dotnet
tar -xvf dotnet-ubuntu.16.04-arm.1.2.0-beta-001291-00.tar.gz -C ~/dotnet
rm ./dotnet-ubuntu.16.04-arm.1.2.0-beta-001291-00.tar.gz

# Install Powershell 6 core (optional)
wget https://github.com/PowerShell/PowerShell/releases/download/v6.0.1/powershell-6.0.1-linux-arm32.tar.gz
mkdir ~/powershell
tar -xvf ./powershell-6.0.1-linux-arm32.tar.gz -C ~/powershell
rm ./powershell-6.0.1-linux-arm32.tar.gz

# Optional HG Pre-reqs - uncomment as required
#sudo apt-get install alsa-utils lame -y # Audio playback
#sudo apt-get install libttspico-utils -y #Embedded speech synthesis engine
#sudo apt-get install lirc liblircclient-dev -y # LIRC Infrared interface
#sudo apt-get install libv4l-0 #Video4Linux camera
#sudo raspi-config nonint do_camera 0 #enable the camera
#sudo modprobe bcm2835-v4l2 # enable camera
#sudo apt-get install libusb-1.0-0 libusb-1.0-0-dev # X10 CM15 Home Automation interface
#sudo apt-get install arduino-mk empty-expect # Arduino programming from HG program editor

# Homegenie-BE
sudo apt-get install dirmngr -y
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/debian raspbianstretch main" | sudo tee /etc/apt/sources.list.d/mono-official.list
sudo apt-get update
sudo apt-get install mono-complete -y
sudo apt-get install ca-certificates-mono -y
sudo apt-get install gdebi-core -y

# Download and install Homegenie-BE
wget https://github.com/Bounz/HomeGenie-BE/releases/download/V1.1.15/homegenie_1.1.15_all.deb
sudo gdebi homegenie_1.1.15_all.deb -n


dpkg-deb -R homegenie_1.1.15_all.deb extracted/
mkdir extracted/etc/
mkdir extracted/etc/default
create /extracted/etc/default/homegenie.service
chmod 555 ./extracted/DEBIAN/*


