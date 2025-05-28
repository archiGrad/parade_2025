# Raspberry Pi Setup Guide

## Setup OS

On another Linux machine, plug in the microSD card.

1. Download and select an OS:
   - `2024-11-19-raspios-bookworm-arm64-lite.img.xyz` (a lightweight operating system that should perform well)

2. Setup the imager:
   ```bash
   sudo rpi-imager -c ~/Downloads/2024-11-19-raspios-bookworm-arm64-lite.img.xyz
   ```

3. This will open up the imager. Specify the microSD card and install the OS.

4. Once installed, insert the microSD card into the Raspberry Pi slot. It will now boot into the OS.

## Initial System Configuration

Update and upgrade the system:
```bash
sudo apt update
sudo apt upgrade
sudo reboot
```

## Desktop Environment Setup

Install and configure LightDM display manager:
```bash
sudo apt install lightdm
sudo systemctl enable lightdm
sudo systemctl start lightdm
sudo reboot
```

Install i3 window manager and related components:
```bash
sudo apt install i3 i3status dmenu i3lock
```
> **Note:** After rebooting, you may only see a terminal login screen. You'll need to manually start LightDM. 
## Essential Software Installation

Install commonly used applications:
```bash
sudo apt install chromium git neofetch tmux zsh nitrogen gnome-terminal vim vim-gtk3 pcmanfm htop feh scrot imagemagick tree
sudo apt update
sudo apt upgrade
sudo reboot
sudo apt autoremove
```

set the i3 config file from the repo as my own
go to ~/.config/i3/config

## Shell Configuration

Set GNOME Terminal as the base terminal and ZSH as the startup shell:
```bash
chsh -s $(which zsh)
```

Install Oh My Zsh:
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

# clone parade config files
git clone @github.com/archiGrad/Parad_pi_config_files


# Game Testing
## Web Environment Setup
in the downloaded repo, there shouold be a PARADE game folder.
Create and configure a Python virtual environment:
```bash
python -m venv website
source website/bin/activate
pip install qrcode flask requests pillow
```

## Performance Testing

Launch Chromium in kiosk mode:
```bash
this works !
chromium --kiosk --disable-gpu-vsync  http://127.0.0.1:5000/
chromium --kiosk --enable-gpu-rasterization --disable-gpu-vsync http://127.0.0.1:5000/
```

For potentially better performance, try:
```bash
chromium --enable-gpu-rasterization --enable-zero-copy
chromium --enable-gpu-rasterization --enable-zero-copy  --enable-precise-memory-info


potential also good flag  --enable-precise-memory-info


# testing options with fps counter

chromium --kiosk  http://127.0.0.1:5000
chromium --kiosk --enable-precise-memory-info http://127.0.0.1:5000
chromium --kiosk --enable-zero-copy  --enable-precise-memory-info http://127.0.0.1:5000
chromium --kiosk --enable-precise-memory-info http://127.0.0.1:5000
chromium --kiosk --enable-gpu-rasterization --enable-zero-copy  --enable-precise-memory-info http://127.0.0.1:5000


```

# set a custom background based on the pi

make a script  that geenrates a background image with specs and raspberry pi id

~/Pictures/bg/make_img.sh

save with correct id! in the script
set the correct p[erm,issions chmod +x make_img.sh

execute thisd script in crontab -e
@reboot /home/joris/Pictures/bg/make_img.sh

#  run this once to disablwe sleep / powwweroff etc
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target


# install tmux and config
put the .tmux.conf file in ~/.tmux.conf


curl -sSL https://your-script-url.com/setup.sh -o setup.sh
chmod +x setup.sh
./setup.sh YOUR_PI_ID
