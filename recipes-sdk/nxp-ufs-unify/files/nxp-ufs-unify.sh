#! /bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 NXP

set -e

VG_NAME="vg_data"
LV_NAME="lv_data"
MOUNT_POINT="/data"

TARGET_VENDOR="MICRON"
TARGET_MODEL="MT128GB"

echo "[INFO] Starting NXP UFS LUNs to Single Volume configuration..."

if lvs "/dev/$VG_NAME/$LV_NAME" >/dev/null 2>&1; then
    echo "[INFO] Logical Volume '$LV_NAME' already exists. Skipping first-time setup."
    exit 0
fi

PV_DEVICES=""

# Scan all available SCSI/block devices
for dev in /sys/block/sd*; do
    [ -e "$dev" ] || continue
    name=$(basename "$dev")

    # Read vendor and model from sysfs and strip spaces
    vendor=""
    if [ -f "$dev/device/vendor" ]; then
        vendor=$(cat "$dev/device/vendor" | tr -d ' ')
    fi

    model=""
    if [ -f "$dev/device/model" ]; then
        model=$(cat "$dev/device/model" | tr -d ' ')
    fi

    # FILTER 1: Check if the device matches MICRON and the target model
    if echo "$vendor" | grep -q "$TARGET_VENDOR"; then
        if echo "$model" | grep -q "$TARGET_MODEL"; then

            scsi_target=$(readlink "$dev/device")
            if [ -z "$scsi_target" ]; then
                echo "[WARNING] Could not determine SCSI address for /dev/$name. Skipping."
                continue
            fi
            
            # Isolate the SCSI address string and extract the 4th element (Hardware LUN ID)
            scsi_addr=$(basename "$scsi_target")
            lun=$(echo "$scsi_addr" | awk -F: '{print $4}')
            
            if [ -z "$lun" ]; then
                echo "[WARNING] Could not parse LUN from address: $scsi_addr. Skipping."
                continue
            fi
            
            if [ "$lun" -eq 0 ] || [ "$lun" -eq 1 ] 2>/dev/null; then
                echo "[INFO] System protection: Skipping /dev/$name (Hardware LUN: $lun)"
                continue
            fi

            echo "[INFO] Selected /dev/$name (Hardware LUN: $lun, Addr: $scsi_addr) for data volume"
            PV_DEVICES="$PV_DEVICES /dev/$name"
        fi
    fi
done

# Strip leading/trailing spaces from the device list
PV_DEVICES=$(echo "$PV_DEVICES" | sed 's/^ *//;s/ *$//')

if [ -z "$PV_DEVICES" ]; then
    echo "[ERROR] No data UFS LUNs found (LUN > 1)!"
    exit 1
fi

echo "[INFO] Final target disks for LVM: $PV_DEVICES"

echo "[INFO] Checking and unmounting active partitions and wiping old partition signatures"
for disk in $PV_DEVICES; do
    if [ -b "$disk" ]; then
        grep "^${disk}" /proc/mounts | awk '{print $1}' | while read -r mounted_p; do
            echo "   -> Lazy unmounting active partition: $mounted_p"
            umount -l "$mounted_p" || true
        done
        wipefs -a -f "$disk" || true
    fi
done

echo "[INFO] Creating Physical Volumes..."
pvcreate --yes --force $PV_DEVICES

echo "[INFO] Creating Volume Group: $VG_NAME..."
vgcreate --yes $VG_NAME $PV_DEVICES

echo "[INFO] Creating Logical Volume: $LV_NAME (100% FREE space)..."
lvcreate --yes -l 100%FREE -n $LV_NAME $VG_NAME

echo "[INFO] Formatting Logical Volume as ext4..."
mkfs.ext4 -F /dev/$VG_NAME/$LV_NAME

echo "[INFO] Optimizing ext4 reserved blocks to 1%..."
tune2fs -m 1 /dev/$VG_NAME/$LV_NAME

echo "[INFO] Finalizing LVM setup and syncing devices..."
sync
vgchange -ay $VG_NAME

echo "[INFO] LVM configuration completed successfully!"