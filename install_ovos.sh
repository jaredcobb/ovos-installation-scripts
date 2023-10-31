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

install_core() {
    echo_info "Installing OVOS core"
    echo

    echo_info "Setting up venv..."
    echo
    : ${OVOS_VENV:=$HOME/venv-ovos}
    python3 -mvenv $OVOS_VENV
    $OVOS_VENV/bin/pip3 install --upgrade setuptools wheel pip
    BINDIR=$OVOS_VENV/bin

    if [[ ! -d ${BINDIR} ]]; then
        mkdir -p ${BINDIR}
    fi

    # Ensure PATH includes BINDIR without duplicating it
    if [[ ! ":$PATH:" == *":${BINDIR}:"* ]]; then
        echo "export PATH=${BINDIR}:$PATH" >> ~/.bashrc
        export PATH=${BINDIR}:$PATH
    fi

    echo_info "Installing neural network requirements..."
    echo
    pip3 install padatious fann2==1.0.7

    # Wake word and STT requirements
    pip3 install tflite_runtime
    pip3 install PyYAML
    pip3 install PyAudio
    pip3 install git+https://github.com/NeonGeckoCom/neon-utils.git \
        git+https://github.com/NeonGeckoCom/neon-stt-plugin-google_cloud_streaming

    echo_info "Installing OVOS core, plugins, and required skills..."
    echo
    # install ovos-core
    pip3 install git+https://github.com/OpenVoiceOS/ovos-backend-client \
        git+https://github.com/OpenVoiceOS/ovos-core \
        git+https://github.com/OpenVoiceOS/ovos-audio \
        git+https://github.com/OpenVoiceOS/ovos-ocp-audio-plugin \
        git+https://github.com/OpenVoiceOS/ovos-messagebus \
        git+https://github.com/OpenVoiceOS/ovos-dinkum-listener \
        git+https://github.com/OpenVoiceOS/ovos-vad-plugin-silero \
        git+https://github.com/OpenVoiceOS/ovos-ww-plugin-precise-lite \
        git+https://github.com/OpenVoiceOS/ovos-stt-plugin-vosk \
        git+https://github.com/OpenVoiceOS/ovos-ww-plugin-pocketsphinx \
        git+https://github.com/OpenVoiceOS/ovos-workshop \
        git+https://github.com/OpenVoiceOS/ovos-lingua-franca \
        git+https://github.com/OpenVoiceOS/ovos-microphone-plugin-alsa \
        git+https://github.com/OpenVoiceOS/ovos-stt-plugin-server \
        git+https://github.com/OpenVoiceOS/ovos-tts-plugin-azure \
        git+https://github.com/OpenVoiceOS/ovos-tts-plugin-mimic3-server \
        git+https://github.com/OpenVoiceOS/ovos-tts-plugin-mimic \
        git+https://github.com/OpenVoiceOS/ovos-tts-plugin-piper \
        git+https://github.com/OpenVoiceOS/ovos-tts-server-plugin \
        git+https://github.com/OpenVoiceOS/ovos-config \
        git+https://github.com/OpenVoiceOS/ovos-utils \
        git+https://github.com/OpenVoiceOS/ovos-bus-client \
        git+https://github.com/OpenVoiceOS/ovos-plugin-manager \
        git+https://github.com/OpenVoiceOS/ovos-cli-client \
        git+https://github.com/OpenVoiceOS/ovos-PHAL \
        git+https://github.com/OpenVoiceOS/ovos-phal-plugin-connectivity-events \
        git+https://github.com/OpenVoiceOS/ovos-phal-plugin-system \
        git+https://github.com/OpenVoiceOS/ovos-PHAL-plugin-ipgeo \
        git+https://github.com/OpenVoiceOS/ovos-PHAL-plugin-oauth \
        git+https://github.com/OpenVoiceOS/ovos-phal-plugin-alsa \
        git+https://github.com/OpenVoiceOS/skill-ovos-volume \
        git+https://github.com/OpenVoiceOS/skill-ovos-stop \
        git+https://github.com/OpenVoiceOS/skill-ovos-date-time

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
        cp $SCRIPT_DIR/keys/google.json $HOME
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

    cp $SCRIPT_DIR/configs/random.sounds.sh $HOME/.local/bin/
    crontab -l 2>/dev/null > tempcron
    echo "*/3 * * * * $HOME/.local/bin/random.sounds.sh" >> tempcron
    crontab tempcron
    rm tempcron

    echo_info "Done installing OVOS core!"
}

install_systemd() {
    echo
    echo_info "Installing systemd files..."
    echo

    # install the hook files
    cp $SCRIPT_DIR/hooks/* $BINDIR/
    chmod +x $BINDIR/ovos-systemd*
    sudo -S cp $SCRIPT_DIR/admin/ovos-systemd-admin-phal /usr/libexec
    sudo -S chmod +x /usr/libexec/ovos-systemd-admin-phal

    # sdnotify is required
    pip3 install sdnotify

    # install the service files
    if [[ ! -d $HOME/.config/systemd/user ]]; then
        mkdir -p $HOME/.config/systemd/user
    fi
    cp $SCRIPT_DIR/services/* $HOME/.config/systemd/user/
    sudo -S cp $SCRIPT_DIR/admin/ovos-admin-phal.service /etc/systemd/system/

    for f in $HOME/.config/systemd/user/*.service ; do
        if [[ $(basename $f) != "ovos.service" ]]; then
            sed -i s,/usr/libexec,${BINDIR},g $f
            sed -i "s,ExecStart=,ExecStart=${OVOS_VENV}/bin/python3 ," $f
        fi
    done

    sudo -S sed -i "s,ExecStart=,ExecStart=${OVOS_VENV}/bin/python3 ," /etc/systemd/system/ovos-admin-phal.service

    if [[ $enabled == "YES" ]]; then
        echo
        echo_info "Enabling service files..."
        echo

        sudo -S loginctl enable-linger $USER

        systemctl --user enable ovos
        systemctl --user enable ovos-messagebus
        systemctl --user enable ovos-dinkum-listener
        systemctl --user enable ovos-audio
        systemctl --user enable ovos-skills
        systemctl --user enable ovos-phal
        sudo -S systemctl enable ovos-admin-phal
        systemctl --user daemon-reload
        sudo -S systemctl daemon-reload
    fi

    cd $SCRIPT_DIR
    echo
    echo_info "Done installing systemd files!"
    echo
}

install_extra_skills() {
    echo
    echo_info "Installing extra skills..."
    echo

    pip3 install git+https://github.com/OpenVoiceOS/skill-ovos-weather

    # Here is where to include your local skills
    if [[ ! -d $HOME/.local/share/mycroft/skills ]]; then
        mkdir -p $HOME/.local/share/mycroft/skills
    fi

    pip3 install git+https://github.com/jaredcobb/ovos-skill-openai

    echo
    echo_info "Done installing extra skills!"
    echo
}

############################################################################################
echo
echo_bright "=============================================================================="
echo_bright "This script will install OpenVoiceOS on your system."
echo_bright "It will use the latest development versions of OVOS core, plugins, and skills."
echo_bright "This script may fail to install if the latest development builds are unstable."
echo_bright "You may want to adjust the release versions of various packages and lock them."
echo_bright "=============================================================================="
echo
echo


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

prompt_bright "Do you want to install systemd files? (Y/n): "
read systemd
if [[ -z "$systemd" || $systemd == y* || $systemd == Y* ]]; then
    systemd="YES"
    echo
    prompt_bright "Do you want to automatically start the ovos services? (Y/n): "
    read enabled
    if [[ -z "$enabled" || $enabled == y* || $enabled == Y* ]]; then
        enabled="YES"
    fi
fi
echo

prompt_bright "Do you want to install extra skills? (Y/n): "
read extra_skills
if [[ -z "$extra_skills" || $extra_skills == y* || $extra_skills == Y* ]]; then
    extra_skills="YES"
fi
echo

echo_bright "We are now ready to install OVOS"
echo
echo

prompt_bright "Do you want to continue? (Y/n): "
read install

if [[ -z "$install" || $install == Y* || $install == y* ]]; then
    if [[ ! -d $HOME/.local/bin ]]; then
        mkdir -p $HOME/.local/bin
    fi
    PATH=$HOME/.local/bin:$PATH
    
    install_core

    if [[ $systemd == "YES" ]]; then
        install_systemd
    fi

    if [[ $extra_skills == "YES" ]]; then
        install_extra_skills
    fi

    echo_info "Done installing OVOS"
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
