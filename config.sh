#!/bin/bash

echo_info() {
    echo -e "\033[94m[INFO]: $1\033[0m"
}

echo_warning() {
    echo -e "\033[91m[WARNING]: $1\033[0m"
}

echo_bright() {
    echo -e "\033[33m$1\033[0m"
}

prompt_bright() {
    echo -e "\033[33m$1\033[0m"
}

configure_core() {
    echo_info "Configuring OVOS core..."
    echo

    # STT requirements
    pip3 install git+https://github.com/NeonGeckoCom/neon-utils.git \
        git+https://github.com/NeonGeckoCom/neon-stt-plugin-google_cloud_streaming

    echo_info "Installing OVOS plugins and required skills..."
    echo
    pip3 install git+https://github.com/OpenVoiceOS/ovos-tts-plugin-azure
    pip3 install git+https://github.com/OpenVoiceOS/skill-ovos-volume
    pip3 install git+https://github.com/OpenVoiceOS/skill-ovos-stop
    pip3 install git+https://github.com/OpenVoiceOS/skill-ovos-date-time

    echo_info "Copying config files..."
    echo
    if [[ ! -d $HOME/.config/mycroft ]]; then
        mkdir -p $HOME/.config/mycroft
    fi
    cp $SCRIPT_DIR/configs/mycroft.conf $HOME/.config/mycroft/

    if [ -f "$SCRIPT_DIR/keys/azure.txt" ]; then
        AZURE_KEY=$(<"$SCRIPT_DIR/keys/azure.txt")

        # Replace ##AZURE_KEY## placeholder in mycroft.conf with the actual Azure Key
        sed -i "s/##AZURE_KEY##/$AZURE_KEY/g" "$HOME/.config/mycroft/mycroft.conf"
    else
        echo_warning "azure.txt does not exist in $SCRIPT_DIR/keys/"
        echo_warning "You will need to manually add your Azure Key to $HOME/.config/mycroft/mycroft.conf"
        echo
    fi

    if [ -f "$SCRIPT_DIR/keys/google.json" ]; then
        cp $SCRIPT_DIR/keys/google.json $HOME/google.json
    else
        echo_warning "google.json does not exist in $SCRIPT_DIR/keys/"
        echo_warning "You will need to manually add your Google service account key to $HOME"
        echo
    fi

    echo_info "Setting up default audio files..."
    echo
    mkdir -p $HOME/.config/files/acknowledge
    mkdir -p $HOME/.config/files/error
    mkdir -p $HOME/.config/files/start_listening
    mkdir -p $HOME/.config/files/end_listening

    cp $SCRIPT_DIR/files/acknowledge/* $HOME/.config/files/acknowledge/
    cp $SCRIPT_DIR/files/error/* $HOME/.config/files/error/
    cp $SCRIPT_DIR/files/start_listening/* $HOME/.config/files/start_listening/
    cp $SCRIPT_DIR/files/end_listening/* $HOME/.config/files/end_listening/

    ln -sfn "$HOME/.config/files/acknowledge/acknowledge1.mp3" "$HOME/.config/files/acknowledge.mp3"
    ln -sfn "$HOME/.config/files/error/error1.mp3" "$HOME/.config/files/error.mp3"
    ln -sfn "$HOME/.config/files/start_listening/start_listening1.mp3" "$HOME/.config/files/start_listening.mp3"
    ln -sfn "$HOME/.config/files/end_listening/end_listening1.mp3" "$HOME/.config/files/end_listening.mp3"

    if [[ ! -d $HOME/.local/bin ]]; then
        mkdir -p $HOME/.local/bin
    fi
    cp $SCRIPT_DIR/configs/random.sounds.sh $HOME/.local/bin/
    crontab -l 2>/dev/null > tempcron
    echo "*/3 * * * * $HOME/.local/bin/random.sounds.sh" >> tempcron
    crontab tempcron
    rm tempcron

    echo_info "Done configuring OVOS core!"
}

install_extra_skills() {
    echo
    echo_info "Installing extra skills..."
    echo

    # Here is where to include your local skills
    if [[ ! -d $HOME/.local/share/mycroft/skills ]]; then
        mkdir -p $HOME/.local/share/mycroft/skills
    fi

    pip3 install git+https://github.com/OpenVoiceOS/skill-ovos-weather
    pip3 install git+https://github.com/jaredcobb/ovos-skill-openai

    echo
    echo_info "Done installing extra skills!"
    echo
}

############################################################################################
echo
echo_bright "=============================================================================="
echo_bright "This script will configure OpenVoiceOS on your system."
echo_bright "It will use the latest development versions of OVOS plugins and skills."
echo_bright "This script may fail to install if the latest development builds are unstable."
echo_bright "You may want to adjust the release versions of various packages and lock them."
echo_bright "=============================================================================="
echo
echo


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VENV_PATH="$HOME/.venvs/ovos"
if [ -d "$VENV_PATH" ]; then
  echo_info "Virtual environment found at $VENV_PATH"
  echo
  source "$VENV_PATH/bin/activate"
  if [ $? -eq 0 ]; then
    echo_info "Virtual environment activated."
    echo
  else
    echo_warning "Failed to activate the virtual environment."
    exit 1
  fi
else
  echo_warning "Virtual environment not found at $VENV_PATH"
  exit 1
fi

prompt_bright "Do you want to install extra skills? (Y/n): "
read extra_skills
if [[ -z "$extra_skills" || $extra_skills == y* || $extra_skills == Y* ]]; then
    extra_skills="YES"
fi
echo

echo_bright "We are now ready to configure OVOS..."
echo
echo

prompt_bright "Do you want to continue? (Y/n): "
read configure

if [[ -z "$configure" || $configure == Y* || $configure == y* ]]; then
    configure_core

    if [[ $extra_skills == "YES" ]]; then
        install_extra_skills
    fi

    echo_info "Done configuring OVOS!"
    echo

    echo_bright "It's recommended to restart your system before running OVOS."
    prompt_bright "Would you like to restart now? [Y/n]: "
    read restart
    if [[ -z "$restart" || $restart == y* || $restart == Y* ]]; then
        echo_bright "See you soon!"
        sudo reboot now
    else
        echo
        echo_bright "Some services and commands may not work until you restart."
        echo
    fi
fi

exit 0
