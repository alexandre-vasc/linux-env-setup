#!/bin/bash

# this script is useful to mount partition automaticly after boot. 
# Useful for non essential partition not take boot time to set up
# suggested location: /usr/local/bin/decrypt_and_mount.sh

# Variables
# Path to the keyfile
KEYFILE=

# list of LUKS partitions UID physical partition + LUKS name
LUKS_PARTITIONS=("")
LVM_VG=""                            # Replace with your LVM volume group name
MOUNT_POINTS=("")
SWAP=""


# 1. Decrypt LUKS Partitions
echo "Decrypting LUKS partitions..."
for entry in "${LUKS_PARTITIONS[@]}"; do
    # Split the entry into UUID and crypt name
    UUID=$(echo "$entry" | awk '{print $1}')
    CRYPT_NAME=$(echo "$entry" | awk '{print $2}')
    
    # Decrypt the partition
    cryptsetup luksOpen --key-file "$KEYFILE" "/dev/disk/by-uuid/$UUID" "$CRYPT_NAME"
    echo "Partition $CRYPT_NAME decrypted successfully."
done

# 2. Activate LVM Volume Group
echo "Activating LVM volume group..."
vgchange -ay "$LVM_VG"

# 3. Mount the Partitions
echo "Mounting the partitions..."
for entry in "${MOUNT_POINTS[@]}"; do
    mount "$entry"
    # Completion message
    echo "Partition mounted successfully at $MOUNT_POINT."
done

swapon  $SWAP


## service file
## add on /etc/systemd/system/decrypt_and_mount.service
[Unit]
Description=Decrypt HDD, Start LVM, and Mount Partition
After=network.target local-fs.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/decrypt_and_mount.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

# activate it
sudo systemctl daemon-reload
sudo systemctl enable decrypt_and_mount.service


