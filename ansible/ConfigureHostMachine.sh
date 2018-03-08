#!/bin/bash
# Install Ansible and Git on the machine.
sudo apt-get update
sudo apt-get install python-pip git python-dev sshpass -y
sudo pip install ansible

# Clone  repo:
git clone https://github.com/davidwallis3101/HGConfigure.git
cd HGConfigure/ansible/

# Execute playbook
# ./playbook.yml

ansible-playbook playbook.yml -i 192.168.0.81, --ask-pass --become -c paramiko 

## Diferent sudo password
ansible-playbook playbook.yml -i 192.168.0.81, --ask-pass --become -c paramiko --ask-become-pass

ansible-playbook playbook.yml -i hosts --ask-pass --become -c paramiko -vvv