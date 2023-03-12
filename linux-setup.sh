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

# Function to check if a variable is not null and not empty
function not_empty {
    if [ -n "$1" ] && [ -n "${1// }" ]; then
        return 1  # variable is not null and not empty
    else
        return 0  # variable is null or empty
    fi
}

CONFIG_FILE="linux-setup.conf"


# install apps
echo "Installing basic apps"
sudo apt remove konqueror
sudo apt install -y flatpak gparted qemu-kvm virt-manager virtinst libvirt-clients \
     bridge-utils libvirt-daemon-system 

echo "Installing flatpak apps"
flatpak install -y flathub com.visualstudio.code
flatpak install -y flathub com.bitwarden.desktop
flatpak install -y flathub org.chromium.Chromium

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
if not_empty "$AUTODELETE_FILES_ON_DOWLOAD_AFTER_DAYS"; then
    sudo apt install -y trash-cli
    (crontab -l ; echo "0 0 * * 0 find ~/Downloads -depth -type f -mtime +$AUTODELETE_FILES_ON_DOWLOAD_AFTER_DAYS -exec trash {} \;") | crontab -
else
    echo "not configuring trash download folder cron job as AUTODELETE_FILES_ON_DOWLOAD_AFTER_DAYS is not set"
fi

AUTOTRASH_MIN_FREE_MB=$(get_config_value "$CONFIG_FILE" "AUTOTRASH_MIN_FREE_MB")
if not_empty "$AUTOTRASH_MIN_FREE_MB"; then
    pip install --user autotrash
    (crontab -l ; echo "0 0 * * 0 autotrash -t --min-free $AUTOTRASH_MIN_FREE_MB > ~/autotrash") | crontab -
else
    echo "not configuring auto trash cron job as AUTOTRASH_MIN_FREE_MB is not set"
fi

GIT_USER_EMAIL=$(get_config_value "$CONFIG_FILE" "GIT_USER_EMAIL")
GIT_USER_FULL_NAME=$(get_config_value "$CONFIG_FILE" "GIT_USER_FULL_NAME")
GIT_EDITOR=$(get_config_value "$CONFIG_FILE" "GIT_EDITOR")
if not_empty "$GIT_USER_FULL_NAME" && not_empty "$GIT_USER_EMAIL" && not_empty "$GIT_EDITOR"; then
    git config --global core.editor $GIT_EDITOR
    git config --global user.name "$GIT_USER_FULL_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
else
    echo "not configuring git as configration is not set on $CONFIG_FILE"
fi 