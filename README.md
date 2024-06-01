# OVOS Installation Scripts

This repository contains Bash scripts and configuration files for automating the installation and setup of my own flavor of OpenVoiceOS (OVOS) on a Raspberry Pi running Raspberry Pi OS. It borrows heavily from the official [OpenVoiceOS raspbian-ovos](https://github.com/OpenVoiceOS/raspbian-ovos) build scripts.

Notable differences between these build scripts and the official build:

- Requires a slightly prepared Raspberry Pi OS image (see Prerequisites below)
- Uses the official [NeonAI Google Streaming STT Plugin](https://github.com/NeonGeckoCom/neon-stt-plugin-google_cloud_streaming)
- Uses the official [OVOS Azure TTS Plugin](https://github.com/OpenVoiceOS/ovos-tts-plugin-azure)
- Uses LCARS computer audio files for the default [OVOS Audio](https://github.com/OpenVoiceOS/ovos-audio) system event sounds.

If you are new to OpenVoiceOS you probably want to run the official image. You can follow the [official guide](https://openvoiceos.github.io/community-docs/) for more details.

If you are interested in building your own custom image, my repository may be a useful starting place.

## Overview

- `init.sh`: Initializes the system by updating, upgrading, and installing dependencies. Then it launches the official [OVOS Installer](https://github.com/OpenVoiceOS/ovos-installer).
- `configure_ovos.sh`: Installs & configures plugins, adds skills, configures OVOS core.
- `/configs`: Configuration files used in initialization and setup.
- `/keys`: Place your `azure.txt` and `google.json` API keys here.
- `/files`: Audio files for OVOS interactions.

## Prerequisites

Before you begin, you will need to complete a few setup tasks:

### Build A New Raspberry Pi OS Image

Ensure that you have a fresh installation of Raspberry Pi OS on your Raspberry Pi. Use the latest Raspberry Pi OS Lite 64-bit edition. I recommend using the [Raspberry Pi Imager](https://www.raspberrypi.com/software/). You may also use software like [balenaEtcher](https://www.balena.io/etcher/) to write the image onto an SD card.

### Configure OS

1. Upon first boot, create a user named `ovos` and set a password.
1. Configure the OS by running `sudo raspi-config` and setting the following items:
1. System Options > Wireless LAN > {Configure Your Wifi}
1. System Options > Boot / Auto Login > Console Autologin
1. Interface Options > SSH > Enable
1. Interface Options > SPI > Enable
1. Interface Options > I2C > Enable
1. Localization Options > Locale > {Configure Your Locale}
1. Localization Options > Timezone > {Configure Your Timezone}
1. Finish (and reboot)

You may now continue to install OVOS directly on the Pi or via SSH. The remaining steps are to be performed on the Pi.

### Launch the Initialization Script

```bash
sh -c "curl -s https://raw.githubusercontent.com/jaredcobb/ovos-installation-scripts/main/init.sh -o init.sh && chmod +x init.sh && sudo ./init.sh && rm init.sh"
```

### Download Repository

Clone this repository in your Pi's `ovos` home directory.

```bash
git clone https://github.com/jaredcobb/ovos-installation-scripts.git ~/ovos-installation-scripts
```

### Setup Your Azure & Google API Keys

This uses the official [NeonAI Google Streaming STT Plugin](https://github.com/NeonGeckoCom/neon-stt-plugin-google_cloud_streaming) and [OVOS Azure TTS Plugin](https://github.com/OpenVoiceOS/ovos-tts-plugin-azure) plugins for Speech To Text and Text To Speech. Both services have free pricing tiers at reasonable levels for normal use. Both services also allow you to setup billing quotas to prevent you from accidentally spending over a certain amount (even $0).

#### Obtaining API Keys

For Azure follow the instructions under the Prerequisites section of the [Quickstart Guide](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/get-started-text-to-speech). After you have created your Resource, make note of your Key and Location/Region.

For Google follow the instructions in the [Set up Speech-To-Text Guide](https://cloud.google.com/speech-to-text/docs/before-you-begin). After you have created your Service Account, downloaded your JSON key.

#### Copy API Keys

It's recommended to SFTP into your Raspberry Pi to copy your keys.

Under the repository there is a directory at `/home/ovos/ovos-installation-scripts/keys`. This is where you will copy your key files.

- Create a file named `azure.txt` and paste the value of your key. Copy it to the `/keys/` directory. See example under `/keys/azure.example.txt`.
- Rename your Google Service Account key file to `google.json`. Copy it to the `/keys/` directory. See example under `/keys/google.example.json`.

#### Azure Location & Voice

By default, the `/home/ovos/ovos-installation-scripts/configs/mycroft.conf` file uses `eastus` as the Azure location. If your Resource is in another location, change that value in `mycroft.conf` before you continue.

You can also change the voice in `mycroft.conf` if you prefer.

### Configure OVOS

#### Launch Configuration Script

```bash
sh -c "curl -s https://raw.githubusercontent.com/jaredcobb/ovos-installation-scripts/main/configure_ovos.sh -o configure_ovos.sh && chmod +x configure_ovos.sh && sudo ./configure_ovos.sh && rm configure_ovos.sh"
```

Reboot.

### Configure OpenAI Skill

These scripts also install my companion [OpenAI fallabck skill](https://github.com/jaredcobb/ovos-skill-openai). My intention is to use OVOS as a general ChatGPT assistant (in addition to any other skills I want to install). If an intent isn't understood (which would be any general question not associated with a skill) it'll be forwarded to the OpenAI API and a response will be read.

The skill is installed but you need an API key. First, create an [OpenAI account](https://platform.openai.com/signup) or sign in. Next, navigate to the [API key page](https://platform.openai.com/account/api-keys) and "Create new secret key", optionally naming the key.

Create a `settings.json` file. See the [example](https://github.com/jaredcobb/ovos-skill-openai/blob/main/settings.example.json) in the skill repo. The `api_key` property is the only one required by default.

See the skill repo for more information on how to customize your ChatGPT model and personality.

Copy your `settings.json` file to `/home/ovos/.config/mycroft/skills/ovos-skill-openai.jaredcobb/settings.json`

Restart OVOS

```bash
ovos-restart
```

### About LCARS Sound Files

I wanted to give OVOS some familiar system event sounds. To give it some variety I created `random.sounds.sh` which is set to run every 3 minutes via cron. It will randomize the file that is symlinked. If you want to setup your own sounds you can just replace the files under the `/files/` directory.

### Aliases and Environment Variables

The `init.sh` script also sets up useful aliases and environment variables:

- `ovos-restart`: Alias to restart OVOS services.
- `l` and `ll`: Aliases for `ls -la`.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
