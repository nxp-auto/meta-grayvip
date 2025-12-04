# QNX SDCARD Image Type Extension
# Extends the original SDCARD class from meta-alb-bsp to add QNX support

# Inherit the original SDCARD class using require (matching UFS pattern)
require classes/image_types_fsl_sdcard.bbclass

# Add QNX dependency to the existing sdcard image task
do_image_sdcard[depends] += "qnx:do_deploy"

# Enhanced _create_fat_subdirs function with better error handling
_create_fat_subdirs() {
    local subdir="$1"
    local current_path=""

    if [ -n "${subdir}" ]; then
        # Split the path and create each directory level
        echo "${subdir}" | tr '/' '\n' | while read dir; do
            if [ -n "${dir}" ]; then
                current_path="${current_path}/${dir}"
                bbnote "Creating directory: ::${current_path}"
                if ! mmd -i "${WORKDIR}/boot.img" "::${current_path}" 2>/dev/null; then
                    # Directory might already exist, check if it's a real error
                    if ! mdir -i "${WORKDIR}/boot.img" "::${current_path}" >/dev/null 2>&1; then
                        bbwarn "Failed to create directory: ::${current_path}"
                        return 1
                    else
                        bbnote "Directory already exists: ::${current_path}"
                    fi
                fi
            fi
        done
    fi
    return 0
}

# Override the boot image generation function to add QNX support
_generate_boot_image() {
    local fat_part_idx=$1
    bbnote "=== QNX-Enhanced SDCARD Boot Image Generation ==="
    
    # Validate input
    if [ -z "$fat_part_idx" ]; then
        bberror "FAT partition index not provided"
        return 1
    fi
    
    # Clean up any existing loop devices for this SDCARD image BEFORE checking if file exists
    if [ -f "${SDCARD}" ]; then
        bbnote "Checking for existing loop devices for ${SDCARD}..."
        EXISTING_LOOPS=$(losetup -j "${SDCARD}" 2>/dev/null | cut -d: -f1)
        if [ -n "${EXISTING_LOOPS}" ]; then
            bbwarn "Found existing loop devices for ${SDCARD}, cleaning up..."
            for loop_dev in ${EXISTING_LOOPS}; do
                bbnote "Processing loop device ${loop_dev}..."
                # Find and unmount any mount points using this loop device
                MOUNT_POINTS=$(mount | grep "^${loop_dev}" | awk '{print $3}')
                for mount_point in ${MOUNT_POINTS}; do
                    bbnote "Unmounting ${mount_point}..."
                    umount "${mount_point}" 2>/dev/null || umount -l "${mount_point}" 2>/dev/null || true
                done
                # Detach the loop device
                bbnote "Detaching loop device ${loop_dev}..."
                losetup -d "${loop_dev}" 2>/dev/null || true
            done
            # Give the system a moment to clean up
            sleep 1
        fi
    fi
    
    # Check if SDCARD file exists and is valid
    if [ ! -f "${SDCARD}" ]; then
        bberror "SDCARD file does not exist: ${SDCARD}"
        return 1
    fi
    
    # Try to repair GPT if needed
    if ! parted -s "${SDCARD}" print >/dev/null 2>&1; then
        bbwarn "GPT table appears corrupted, attempting to repair..."
        if command -v sgdisk >/dev/null 2>&1; then
            sgdisk -e "${SDCARD}" || bbwarn "Failed to repair GPT table"
        fi
    fi
    
    # Create boot partition image with error checking
    BOOT_BLOCKS=$(LC_ALL=C parted -s "${SDCARD}" unit b print 2>/dev/null \
        | awk "/ $fat_part_idx / { print substr(\$4, 1, length(\$4 -1)) / 1024 }")
    
    if [ -z "$BOOT_BLOCKS" ] || [ "$BOOT_BLOCKS" = "0" ]; then
        bberror "Could not determine boot partition size for partition $fat_part_idx"
        return 1
    fi
    
    bbnote "Boot partition size: $BOOT_BLOCKS KB"
    
    # mkdosfs will sometimes use FAT16 when it is not appropriate,
    # resulting in a boot failure from SYSLINUX. Use FAT32 for
    # images larger than 512MB, otherwise let mkdosfs decide.
    if [ $(printf "%u / 1024\n" $BOOT_BLOCKS | bc) -gt 512 ]; then
        FATSIZE="-F 32"
    fi
    
    rm -f "${WORKDIR}/boot.img"
    bvid="`echo ${BOOTDD_VOLUME_ID} | head -c 10`"
    if ! mkfs.vfat -n "$bvid" -S 512 ${FATSIZE} -C "${WORKDIR}/boot.img" $BOOT_BLOCKS; then
        bberror "Failed to create FAT filesystem"
        return 1
    fi
    
    # Create QNX boot directory structure (no linux subdirectory)
    bbnote "Creating boot directory structure..."
    if ! _create_fat_subdirs "BOOT"; then
        bberror "Failed to create BOOT directory"
        return 1
    fi
    
    if ! _create_fat_subdirs "BOOT/qnx"; then
        bberror "Failed to create BOOT/qnx directory"
        return 1
    fi
    
    # Create DTB directory if specified
    if [ -n "${SD_FAT_DTB_DIR}" ]; then
        if ! _create_fat_subdirs "${SD_FAT_DTB_DIR}"; then
            bberror "Failed to create DTB directory: ${SD_FAT_DTB_DIR}"
            return 1
        fi
    fi
    
    # Skip Linux kernel image copy - QNX only
    bbnote "Skipping Linux kernel image copy - QNX-only boot partition"
    
    # Check if QNX IFS file exists and copy it
    if [ -n "${QNX_IFS_PATH}" ]; then
        QNX_IFS_FILE="${DEPLOY_DIR_IMAGE}/$(basename ${QNX_IFS_PATH})"
        bbnote "Adding QNX IFS file: ${QNX_IFS_FILE} to /BOOT/qnx/"
        if ! mcopy -i "${WORKDIR}/boot.img" -s "${QNX_IFS_FILE}" "::/BOOT/qnx/$(basename ${QNX_IFS_PATH})"; then
            bbwarn "Failed to copy QNX IFS file: ${QNX_IFS_FILE}"
            return 1
        fi
    else
        bbwarn "QNX_IFS_PATH not set"
        return 0
    fi

    bbnote "QNX files successfully added to boot partition"
    
    if [ -n "${KERNEL_DEVICETREE_EXT}" ]; then
        KERNEL_DEVICETREE_IN_USE="${KERNEL_DEVICETREE_EXT}"
    else
        KERNEL_DEVICETREE_IN_USE="${KERNEL_DEVICETREE}"
    fi
    
    # Copy device tree files
    if test -n "${KERNEL_DEVICETREE_IN_USE}"; then
        bbnote "Copying device tree files..."
        kernel_bin="`readlink ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin 2>/dev/null || echo ""`"
        for DTB_FILE in ${KERNEL_DEVICETREE_IN_USE}; do
            DTB_BASE_NAME="$(basename -- "${DTB_FILE}" .dtb)"
            DTB_PATH=""
            kernel_bin_for_dtb=""
            
            if [ -e "${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${DTB_BASE_NAME}.dtb" ]; then
                DTB_PATH="${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${DTB_BASE_NAME}.dtb"
                kernel_bin_for_dtb="`readlink $DTB_PATH 2>/dev/null | sed "s,$DTB_BASE_NAME,${MACHINE},;s,\.dtb$,.bin,g"`"
            elif [ -e "${DEPLOY_DIR_IMAGE}/${DTB_BASE_NAME}.dtb" ]; then
                DTB_PATH="${DEPLOY_DIR_IMAGE}/${DTB_BASE_NAME}.dtb"
                kernel_bin_for_dtb="`readlink $DTB_PATH 2>/dev/null | sed "s,$DTB_BASE_NAME,${KERNEL_IMAGETYPE},;s,\.dtb$,.bin,g"`"
                # in case "${kernel_bin_for_dtb}" is empty, it means that $DTB_PATH is not a symlink, but the dtb file itself
                if [ -z "${kernel_bin_for_dtb}" ]; then
                    kernel_bin_timestamp="`echo ${kernel_bin} | sed -e "s/^Image--//" -e "s/.bin//"`"
                    kernel_bin_for_dtb="`find ${DEPLOY_DIR_IMAGE} -maxdepth 1 -type l -exec basename {} \; 2>/dev/null | grep "${kernel_bin_timestamp}.dtb" | sed "s,$DTB_BASE_NAME,${KERNEL_IMAGETYPE},;s,\.dtb$,.bin,g"`"
                fi
            fi
            
            if [ -n "${DTB_PATH}" ]; then
                # Copy DTB regardless of kernel timestamp matching (for QNX use)
                FAT_DTB_DEST="::/${SD_FAT_DTB_DIR}/${DTB_BASE_NAME}.dtb"
                if ! mcopy -i "${WORKDIR}/boot.img" -s "${DTB_PATH}" "${FAT_DTB_DEST}"; then
                    bbwarn "Failed to copy DTB file: ${DTB_PATH}"
                fi
            else
                bbwarn "${DTB_FILE} does not exist."
            fi
        done
    fi
    
    # Skip extlinux.conf - not needed for QNX
    bbnote "Skipping extlinux.conf - QNX-only boot partition"
    
    # Add extra boot images in the SDCARD boot partition
    bbnote "Adding extra boot images..."
    for file in ${@" ".join(get_files_from_extra_files(d))}
    do
        if ! add_extra_boot_img "${file}" "${WORKDIR}/boot.img"; then
            bbwarn "Failed to add extra boot image: ${file}"
        fi
    done
    
    # Handle U-Boot environment files with proper directory creation
    if [ "${SDCARD_PARTITIONING_SCHEME}" = "gpt" ] && [ -n "${UBOOT_ENV_SDCARD_FILE}" ]; then
        # Create the firmware directory structure that the base class expects
        bbnote "Creating firmware directory structure..."
        if ! _create_fat_subdirs "FIRMWARE"; then
            bbwarn "Failed to create FIRMWARE directory"
        elif ! _create_fat_subdirs "FIRMWARE/NXP"; then
            bbwarn "Failed to create FIRMWARE/NXP directory"
        elif ! _create_fat_subdirs "FIRMWARE/NXP/${MACHINE}"; then
            bbwarn "Failed to create FIRMWARE/NXP/${MACHINE} directory"
        elif ! _create_fat_subdirs "FIRMWARE/NXP/${MACHINE}/u-boot"; then
            bbwarn "Failed to create FIRMWARE/NXP/${MACHINE}/u-boot directory"
        else
            # Now copy the environment file
            if [ -e "${DEPLOY_DIR_IMAGE}/${UBOOT_ENV_SDCARD_FILE}" ]; then
                if ! mcopy -i "${WORKDIR}/boot.img" \
                -s "${DEPLOY_DIR_IMAGE}/${UBOOT_ENV_SDCARD_FILE}" \
                "::/FIRMWARE/NXP/${MACHINE}/u-boot/env.txt"; then
                    bbwarn "Failed to copy U-Boot environment file"
                fi
            else
                bbwarn "U-Boot environment file ${UBOOT_ENV_SDCARD_FILE} not found in ${DEPLOY_DIR_IMAGE}"
            fi
        fi
        
        # Also create the SD_FAT_ENV_DIR if it's different
        if [ -n "${SD_FAT_ENV_DIR}" ] && [ "${SD_FAT_ENV_DIR}" != "FIRMWARE/NXP/${MACHINE}/u-boot" ]; then
            if ! _create_fat_subdirs "${SD_FAT_ENV_DIR}"; then
                bbwarn "Failed to create environment directory: ${SD_FAT_ENV_DIR}"
            elif [ -e "${DEPLOY_DIR_IMAGE}/${UBOOT_ENV_SDCARD_FILE}" ]; then
                if ! mcopy -i "${WORKDIR}/boot.img" \
                -s "${DEPLOY_DIR_IMAGE}/${UBOOT_ENV_SDCARD_FILE}" \
                "::${SD_FAT_ENV_DIR}/env.txt"; then
                    bbwarn "Failed to copy U-Boot environment file to ${SD_FAT_ENV_DIR}"
                fi
            fi
        fi
    fi
    
    bbnote "QNX-enhanced boot image generation completed successfully"
    return 0
}

