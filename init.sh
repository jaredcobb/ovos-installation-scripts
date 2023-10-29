#!/bin/bash
sudo apt -y update && sudo apt -y upgrade

sudo apt install -y build-essential python3-dev python3-pip python3-venv \
    swig libssl-dev libfann-dev portaudio19-dev \
    libpulse-dev cmake libncurses-dev pulseaudio-utils pulseaudio \
    espeak-ng mpg123 speedtest-cli vim

sudo install -v -m 0644 ./configs/97-ovos.conf "/etc/sysctl.d/97-ovos.conf"

sudo wget -O /etc/motd https://gist.githubusercontent.com/jaredcobb/304281217b15da56c7a4b1c2e3c8e68f/raw/f10ec781d5d57012a1c029e02ddfb5f45ee493c4/motd

echo "alias l='ls -la'" >> ~/.bashrc
echo "alias ll='ls -la'" >> ~/.bashrc
echo "alias ovos-restart='systemctl --user restart ovos'" >> ~/.bashrc
echo "export PATH=\$PATH:/home/ovos/.local/bin" >> ~/.bashrc

echo "Done initializing the server."
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