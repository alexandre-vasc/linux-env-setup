#!/bin/bash

# Function to retrieve a configuration value from a file
# the file $1 is a configuration file, in the format
# key=value
get_config_value() {
    local config_file="$1"
    local config_name="$2"
    local config_value=$(grep "^$config_name=" "$config_file" | cut -d= -f2)
    echo "$config_value"
}

CONFIG_FILE=$1
if [ $# -gt 0 ]; then
    echo "Config file is $1"
else
    echo "config file not set. with as $0 config-file.conf"
    exit 1
fi

# install apps
echo "Installing basic apps"
sudo apt remove konqueror speech-dispatcher

INSTALL_VIRT_UTILS=$(get_config_value "$CONFIG_FILE" "INSTALL_VIRT_UTILS")
if [[ -n  "$INSTALL_VIRT_UTILS" ]]; then
    sudo apt install -y flatpak gparted qemu-kvm virt-manager virtinst libvirt-clients \
         bridge-utils libvirt-daemon-system   
fi

sudo apt install -y unrar-free chromium pip


#echo "Installing flatpak apps"
#flatpak install -y flathub com.visualstudio.code
#flatpak install -y flathub com.bitwarden.desktop

## note: chrome on flatpak is not hardware accelerated
#flatpak install -y flathub org.chromium.Chromium

# Check if crontab exists for the current user
if crontab -l &> /dev/null; then
    echo "Crontab exists for $(whoami)"
else
    # Create new crontab file
    echo "Creating new crontab file for $(whoami)"
    crontab - <<EOF
# Empty crontab
EOF
fi

AUTODELETE_FILES_ON_DOWLOAD_AFTER_DAYS=$(get_config_value "$CONFIG_FILE" "AUTODELETE_FILES_ON_DOWLOAD_AFTER_DAYS")
if [[ -n  "$AUTODELETE_FILES_ON_DOWLOAD_AFTER_DAYS" ]]; then
    sudo apt install -y trash-cli
    (crontab -l ; echo "0 0 * * 0 find ~/Downloads/ -depth -type f -mtime +$AUTODELETE_FILES_ON_DOWLOAD_AFTER_DAYS -exec trash {} \;") | crontab -
else
    echo "not configuring trash download folder cron job as AUTODELETE_FILES_ON_DOWLOAD_AFTER_DAYS is not set"
fi

AUTOTRASH_MIN_FREE_MB=$(get_config_value "$CONFIG_FILE" "AUTOTRASH_MIN_FREE_MB")
if [[ -n  "$AUTOTRASH_MIN_FREE_MB" ]]; then
    pip install --user autotrash
    (crontab -l ; echo "0 0 * * 0 autotrash -t --min-free $AUTOTRASH_MIN_FREE_MB > ~/autotrash") | crontab -
else
    echo "not configuring auto trash cron job as AUTOTRASH_MIN_FREE_MB is not set"
fi

GIT_USER_EMAIL=$(get_config_value "$CONFIG_FILE" "GIT_USER_EMAIL")
GIT_USER_FULL_NAME=$(get_config_value "$CONFIG_FILE" "GIT_USER_FULL_NAME")
GIT_EDITOR=$(get_config_value "$CONFIG_FILE" "GIT_EDITOR")
if [[ -n  "$GIT_USER_FULL_NAME" ]] && [[ -n   "$GIT_USER_EMAIL" ]] && [[ -n  "$GIT_EDITOR" ]]; then
    git config --global core.editor $GIT_EDITOR
    git config --global user.name "$GIT_USER_FULL_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
else
    echo "not configuring git as configration is not set on $CONFIG_FILE"
fi 

        
SWAP_FILE_SIZE=$(get_config_value "$CONFIG_FILE" "SWAP_FILE_SIZE")
SWAP_FILE_PATH=$(get_config_value "$CONFIG_FILE" "SWAP_FILE_PATH")
if [[ -n "$SWAP_FILE_SIZE" ]] && [[ -n "$SWAP_FILE_PATH" ]]; then
    if [ -e $SWAP_FILE_PATH ]; then
        echo "Swap file $SWAP_FILE_PATH already exists"
    else    
        echo "Creating swap file"
        sudo cp /etc/fstab /etc/fstab.bak
        sudo fallocate -l $SWAP_FILE_SIZE $SWAP_FILE_PATH
        sudo chmod 600 $SWAP_FILE_PATH
        sudo mkswap $SWAP_FILE_PATH
        sudo swapon $SWAP_FILE_PATH
        echo "$SWAP_FILE_PATH swap swap defaults 0 0" | sudo tee -a /etc/fstab
    fi
else
    echo "not configuring swap file as SWAP_FILE_SIZE or SWAP_FILE_PATH are not set"
    echo "SWAP_FILE_SIZE: $SWAP_FILE_SIZE, SWAP_FILE_PATH: $SWAP_FILE_PATH"
fi


sudo apt autoremove -y