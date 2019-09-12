#!/bin/bash
# script to install docker and then jenkin image inside of docker

# install docker
#in order to ensure the downloads are valid, add the GPG key for the official Docker repository to your system
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker repository to APT sources
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# update the package database with the Docker packages from the newly added repo
sudo apt-get update

# Make sure you are about to install from the Docker repo instead of the default Ubuntu 16.04 repo
apt-cache policy docker-ce

# install docker
sudo apt-get install -y docker-ce

# Below command stuck in the prompt, so better not use here
#sudo systemctl status docker
#use systemd to manage which services start when the system boots
sudo systemctl enable docker

# Command to check if docker group exist : grep -i docker /etc/group
#If you want to avoid typing sudo whenever you run the docker command, add your username to the docker group
#Note: first time the script did not work as group addition requires logout and login
# bash -l -c id         --execute the command toget the group details and check for docker membership
# Another option would be to create specific user  and run using that user
#sudo useradd aniket
#sudo usermod -aG docker aniket
#sudo su - aniket -c id
#
#then docker run command 
sudo usermod -aG docker ${USER}
#Getting a shell with the new group without logging out and in again
su - $USER
#or try this exec su -l $USER

# install Jenkins in docker now

mkdir -p /data/jenkins_home
chown 1000:1000 /data/jenkins_home

# Start docker
docker run -d -p 49001:8080 -v /data/jenkins_home:/var/jenkins_home:z -t jenkins/jenkins

# Show endpoints
echo 'Jenkins Installed'
echo 'Access Jenkins using URL- http://'$(curl -s ifconfig.co)':49001'

