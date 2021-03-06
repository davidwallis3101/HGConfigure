#!/bin/bash
# Install Ansible and Git on the machine.
sudo apt-get update
sudo apt-get install python-pip git python-dev sshpass -y
sudo pip install ansible

# Add modules
# ansible-galaxy install sansible.rsyslog

# Clone my repo:
git clone https://github.com/davidwallis3101/HGConfigure.git
cd HGConfigure/ansible/

# Execute playbook
# ./playbook.yml

ansible-galaxy install -p ./roles -r roles.yml

# update if needed
git pull origin master

#ansible-playbook playbook.yml -i 192.168.0.81, --ask-pass --become -c paramiko

ansible-playbook playbook.yml -i 192.168.0.81, --ask-pass --become -u pi -c paramiko
ansible-playbook playbook.yml -i 192.168.0.161, --ask-pass --become -u pi -c paramiko
# ansible-playbook playbook.yml -i hosts --ask-pass --become -u pi -c paramiko

## Diferent sudo password
#ansible-playbook playbook.yml -i 192.168.0.81, --ask-pass --become -c paramiko --ask-become-pass

#ansible-playbook playbook.yml -i hosts --ask-pass --become -c paramiko -vvv
