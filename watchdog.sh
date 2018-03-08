# Install Watchdog Daemon
#https://www.domoticz.com/wiki/Setting_up_the_raspberry_pi_watchdog
#https://github.com/jpswade/pims

# sudo apt-get install watchdog chkconfig 

# echo "bcm2708_wdog" | sudo tee -a /etc/modules
# sudo modprobe bcm2708_wdog
# sudo echo bcm2708_wdog >> /etc/modules
# sudo chkconfig watchdog on
# sudo update-rc.d watchdog defaults
# sudo /etc/init.d/watchdog start


#sudo cp /etc/watchdog.conf.bak /etc/watchdog.conf.bak
#sudo sh -c "watchdog-device = /dev/watchdog > /etc/watchdog.conf"
#sudo sh -c "watchdog-timeout = 14 >> /etc/watchdog.conf" 
#sudo sh -c "realtime = yes >> /etc/watchdog.conf"
#sudo sh -c "priority = 1 >> /etc/watchdog.conf"
#sudo sh -c "interval = 4 >> /etc/watchdog.conf"

sudo nano /etc/watchdog.conf

#uncomment the lines file and change and set them to:
	max-load-1              = 24

sudo /etc/init.d/watchdog restart	

# Test with a fork bomb
#  : (){ :|:& };:



# Enable Watchdog Kernel Module
echo "bcm2708_wdog" | sudo tee -a /etc/modules
sudo modprobe bcm2708_wdog

# Install Watchdog Daemon
sudo apt-get install watchdog --yes

#configure to run at boot
sudo update-rc.d watchdog defaults
sudo nano /etc/watchdog.conf

#uncomment the lines file and change and set them to:
	max-load-1              = 24
	file                    = /usr/local/bin/homegenie/log/homegenie.log
	change                  = 600

# restart the service
sudo /etc/init.d/watchdog restart