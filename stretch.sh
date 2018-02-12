# Launch raspi-config and enable ssh

sudo apt-get update

# Powershell 6 core
sudo apt-get install libunwind8
wget https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-rc.2/powershell-6.0.0-rc.2-linux-arm32.tar.gz
mkdir ~/powershell
tar -xvf ./powershell-6.0.0-rc.2-linux-arm32.tar.gz -C ~/powershell
rm ./powershell-6.0.0-rc.2-linux-arm32.tar.gz

# Install .net core (From here https://dotnetcorechris.github.io/dotnetcoreonraspberrypi.html)
sudo apt-get install libunwind8 libunwind8-dev gettext libicu-dev liblttng-ust-dev libcurl4-openssl-dev libssl-dev uuid-dev -y
wget https://github.com/dotnet/core-setup/files/716356/dotnet-ubuntu.16.04-arm.1.2.0-beta-001291-00.tar.gz
mkdir ~/dotnet
tar -xvf dotnet-ubuntu.16.04-arm.1.2.0-beta-001291-00.tar.gz -C ~/dotnet
cd ~/dotnet

# Homegenie-BE
sudo apt-get install mono-complete -y
wget https://github.com/Bounz/HomeGenie-BE/releases/download/V1.1.14/homegenie_1.1.14_all.deb
sudo dpkg -i homegenie_1.1.14_all.deb