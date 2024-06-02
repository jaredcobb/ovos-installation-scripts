#!/bin/bash

sudo raspi-config nonint do_change_locale en_US.UTF-8
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0

sudo apt -y update && sudo apt -y upgrade

sudo apt install -y speedtest-cli vim git

sudo wget -O /etc/motd https://gist.githubusercontent.com/jaredcobb/304281217b15da56c7a4b1c2e3c8e68f/raw/f10ec781d5d57012a1c029e02ddfb5f45ee493c4/motd

echo "alias l='ls -la'" >> ~/.bashrc
echo "alias ll='ls -la'" >> ~/.bashrc
echo "alias ovos-restart='systemctl --user restart ovos'" >> ~/.bashrc
echo "export PATH=\$PATH:/home/ovos/.local/bin" >> ~/.bashrc

echo "Done initializing the server..."
echo

read -p "Would you like to restart now? [Y/n]: " restart
if [[ -z "$restart" || $restart == y* || $restart == Y* ]]; then
    echo "See you soon!"
    sudo reboot now
else
    echo
    echo "You will need to restart before running install_ovos.sh"
    echo
fi
