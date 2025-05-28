#!/bin/bash

# Raspberry Pi Parade Setup Script
# This script automates the setup of Raspberry Pi devices for the Parade project
# Run as: bash setup.sh [RASPBERRY_PI_ID]
# If no ID is provided, you will be prompted to enter one manually

echo "====================================================="
echo "       Raspberry Pi Parade Setup Script"
echo "====================================================="

# Create a log file
LOG_FILE="setup_log.txt"
exec > >(tee -a "$LOG_FILE") 2>&1

# Get Raspberry Pi identifier or prompt for a manual ID
if [ -z "$1" ]; then
    echo "No Raspberry Pi ID provided as argument."
    read -p "Enter Raspberry Pi ID manually: " PI_ID
else
    PI_ID="$1"
fi
echo "Setting up Raspberry Pi with ID: $PI_ID"

# Update and upgrade the system
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install essential packages
echo "Installing essential packages..."
sudo apt install -y lightdm i3 i3status dmenu i3lock chromium-browser git neofetch tmux zsh nitrogen \
                   gnome-terminal vim vim-gtk3 pcmanfm htop feh scrot imagemagick python3-venv python3-pip \
                   python3-flask

# Set up ZSH and Oh My Zsh
echo "Setting up ZSH and Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Set ZSH as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting ZSH as default shell..."
    chsh -s $(which zsh)
fi

# Create directories
echo "Creating required directories..."
mkdir -p "$HOME/.config/i3"
mkdir -p "$HOME/Pictures/bg"

# Clone Parade config files
echo "Cloning Parade config files..."
if [ ! -d "$HOME/Parade_pi_config_files" ]; then
    git clone https://github.com/archiGrad/Parad_pi_config_files "$HOME/Parade_pi_config_files"
else
    echo "Parade config repository already exists. Updating..."
    cd "$HOME/Parade_pi_config_files"
    git pull
    cd "$HOME"
fi

# Copy config files
echo "Copying configuration files..."
cp "$HOME/Parade_pi_config_files/config" "$HOME/.config/i3/config"
cp "$HOME/Parade_pi_config_files/alanpeabody.zsh-theme" "$HOME/.oh-my-zsh/themes/"
cp "$HOME/Parade_pi_config_files/make_img.sh" "$HOME/Pictures/bg/"

# Set execute permissions for the background image script
chmod +x "$HOME/Pictures/bg/make_img.sh"

# Setup PARADE game folder
echo "Setting up PARADE game environment..."
if [ ! -d "$HOME/website" ]; then
    python3 -m venv "$HOME/website"
    source "$HOME/website/bin/activate"
    pip install qrcode flask requests pillow
    deactivate
fi

# Copy PARADE game files
echo "Copying PARADE game files..."
mkdir -p "$HOME/PARADE_webgl_g1"
cp -r "$HOME/Parade_pi_config_files/PARADE_webgl_g1/"* "$HOME/PARADE_webgl_g1/"

# Update make_img.sh with the correct Pi ID
echo "Updating background image script with Pi ID: $PI_ID"
sed -i "s/RASPBERRY_PI_ID=.*/RASPBERRY_PI_ID=\"$PI_ID\"/" "$HOME/Pictures/bg/make_img.sh"

# Create a reference script for manually running the game (not auto-started)
echo "Creating reference script for manually running the game..."
cat > "$HOME/start_parade.sh" << 'EOL'
#!/bin/bash

# Start PARADE application
cd "$HOME"
source "$HOME/website/bin/activate"
cd "$HOME/PARADE_webgl_g1"
python3 app.py &

# Wait for Flask to start
sleep 5

# Start Chromium in kiosk mode
chromium-browser --kiosk --enable-gpu-rasterization --enable-zero-copy --enable-precise-memory-info http://127.0.0.1:5000/ &
EOL

chmod +x "$HOME/start_parade.sh"

echo "Note: The game will not start automatically. Use $HOME/start_parade.sh to launch it manually."

# Create a tmux configuration file
echo "Setting up tmux configuration..."
cat > "$HOME/.tmux.conf" << 'EOL'
# Set the prefix to Ctrl-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Reload config file with r
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Enable mouse mode
set -g mouse on

# Set easier window split keys
bind-key v split-window -h
bind-key h split-window -v

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1
EOL

# Set up crontab to run background image script at reboot
echo "Setting up crontab for background image generation..."
(crontab -l 2>/dev/null; echo "@reboot $HOME/Pictures/bg/make_img.sh") | crontab -

# Disable sleep/suspend
echo "Disabling sleep and suspend..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Enable LightDM display manager
echo "Enabling LightDM display manager..."
sudo systemctl enable lightdm
sudo systemctl start lightdm

echo "====================================================="
echo "Setup completed successfully!"
echo "Raspberry Pi ID: $PI_ID"
echo "Please reboot the system for all changes to take effect."
echo "====================================================="

# Ask for reboot
read -p "Do you want to reboot now? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
fi
