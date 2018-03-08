#!/bin/bash
# Install Ansible and Git on the machine.
sudo apt-get update
sudo apt-get install python-pip git python-dev sshpass -y
sudo pip install ansible