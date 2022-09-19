#!/bin/bash

#############################################################
# Bash script to install xfce4 with VNC over ngrok and wine #
# For Google Cloud Shell                                    #
# Copyright 2022 giangvinhloc610                            #
#############################################################

# Install vncserver & xfce4
echo Installing vncserver and xfce4...
sudo apt update
sudo apt install tigervnc-standalone-server xfce4 xfce4-terminal xfce4-taskmanager dbus-x11 --no-install-recommends -y

# Setup wine apt repo
echo Adding wine repo...
sudo dpkg --add-architecture i386
sudo wget -nc -O /usr/share/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -nc -P /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bullseye/winehq-bullseye.sources

# Temporary fix for GPG key error
sudo mkdir -pm755 /etc/apt/keyrings
sudo mv /usr/share/keyrings/winehq-archive.key /etc/apt/keyrings/winehq-archive.key

sudo apt update

# Install wine
echo Installing wine...
sudo apt install --install-recommends winehq-staging -y

# Start vncserver
vncserver
export DISPLAY=:1
xfce4-session &

# Wait for xfce to output log
sleep 5

# Configure WINEPREFIX
# Google Cloud Shell has a really small /home parition (5GB), so you might need to change the WINEPREFIX to somewhere else
echo Google Cloud Shell has a small partition of 5GB, would you wish to set WINEPREFIX to /tmp, which has much more space?
echo Please note that data outside $HOME will be deleted after each Google Cloud Shell session.
read -p "Your choice [y/N]: " answer

if [ "$answer" != "${answer#[Yy]}" ] ; then
    mkdir /tmp/wineprefix
    export WINEPREFIX=/tmp/wineprefix
    echo 'export WINEPREFIX=/tmp/wineprefix' >> ~/.bashrc
    echo Your WINEPREFIX will now be $WINEPREFIX
fi

# Install winetrick
echo Installing winetricks...
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x winetricks
sudo mv winetricks /usr/bin/

# wineboot
echo Starting wineboot...
wineboot &

# Get ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xvf ngrok-v3-stable-linux-amd64.tgz
chmod +x ./ngrok
sudo mv ngrok /usr/bin/ # Move to /usr/bin
rm ngrok-v3-stable-linux-amd64.tgz # Clean up

# ngrok login
echo Now go to https://dashboard.ngrok.com/get-started/setup and find your token in step 2, then put it here:
read token

# Check if the user actually copy the whole add-authtoken command or just the token itself
if [[ $token == *"add-authtoken"* ]]; then
    $token
else
        ngrok config add-authtoken $token
fi

# Done, enjoy your wine
echo Done, enjoy your Wine

# Open ngrok tunnel
ngrok tcp 5901 --region ap # You might change the region for selecting the closet server to your place :)
