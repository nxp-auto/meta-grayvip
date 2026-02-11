# QNX UFS Image Type Extension
# Extends the original UFS class from meta-alb-bsp to add QNX support

# Inherit the original UFS class
require classes/image_types_fsl_ufs.bbclass

# Override ESP partition size for QNX builds
ESP_PARTITION_EXTRA_SPACE_MIB = "28"

# Add dependency on QNX IFS recipe
do_image_ufs[depends] += "qnx:do_deploy"

# QNX-specific LUN1 generation function
generate_nxp_ufs_lun1() {
    bbnote "=== QNX UFS LUN1 Generation ==="

    # Clean existing UFS LUN1 file
    if [ -f "${UFS_LUN1_NAME}" ]; then
        bbnote "Removing existing UFS LUN1 file: ${UFS_LUN1_NAME}"
        rm -f "${UFS_LUN1_NAME}"
    fi
    bbnote "DEPLOY_DIR_IMAGE ${DEPLOY_DIR_IMAGE} "
    
    # Calculate partition sizes
    ESP_PARTITION_ROUND_SIZE_KIB=$(roundup_size_kib ${ESP_PARTITION_SIZE_KIB} ${OPTIMAL_ALIGNMENT_KIB})
    ROOTFS_PARTITION_ROUND_SIZE_KIB=$(roundup_size_kib ${ROOTFS_PARTITION_SIZE_KIB} ${OPTIMAL_ALIGNMENT_KIB})

    gpt_size_kib=$(get_gpt_size_kib ${UFS_SECTOR_SIZE})
    gpt_round_size_kib=$(roundup_size_kib ${gpt_size_kib} ${OPTIMAL_ALIGNMENT_KIB})
    FIRST_PARTITION_START_KIB=$(get_first_partition_start_kib ${UFS_SECTOR_SIZE})

    LUN1_TOTAL_SIZE=$(echo "${FIRST_PARTITION_START_KIB} + ${ESP_PARTITION_ROUND_SIZE_KIB} + ${ROOTFS_PARTITION_ROUND_SIZE_KIB} + ${gpt_round_size_kib}" | bc)

    # Create UFS LUN1 image
    bbnote "Creating QNX UFS LUN1 with size ${LUN1_TOTAL_SIZE} KiB"
    dd if=/dev/zero of="${UFS_LUN1_NAME}" bs=1K count=${LUN1_TOTAL_SIZE}

    # Set up partitioning
    export PARTED_SECTOR_SIZE=${UFS_SECTOR_SIZE}
    parted -s "${UFS_LUN1_NAME}" mklabel gpt

    # Create partitions
    create_partition ${UFS_LUN1_NAME} ${UFS_SECTOR_SIZE} ${ESP_PARTITION_NAME} ${ESP_PARTITION_SIZE_SECTORS} "fat16"
    parted -s "${UFS_LUN1_NAME}" set 1 esp on
    create_partition ${UFS_LUN1_NAME} ${UFS_SECTOR_SIZE} ${ROOTFS_PARTITION_NAME} ${ROOTFS_PARTITION_SIZE_SECTORS} "${UFS_ROOTFS_EXT}"

    # Create QNX boot partition
    bbnote "Creating QNX boot partition..."
    rm -f "${UFS_LUN_DEPLOYDIR}/kernel.part"
    mkfs.vfat -n boot -S ${UFS_SECTOR_SIZE} -C "${UFS_LUN_DEPLOYDIR}/kernel.part" ${ESP_PARTITION_SIZE_KIB}
    
    # Create boot directory structure
    mmd -i "${UFS_LUN_DEPLOYDIR}/kernel.part" "::/BOOT" "::/BOOT/qnx"

    # Copy QNX IFS file
    bbnote "Adding QNX IFS file ($(stat -c%s "${DEPLOY_DIR_IMAGE}/qnx-ifs.ui") bytes)"
    mcopy -i "${UFS_LUN_DEPLOYDIR}/kernel.part" -s "${DEPLOY_DIR_IMAGE}/qnx-ifs.ui" "::/BOOT/qnx/qnx-ifs.ui"

    # Write partitions to UFS image
    bbnote "Writing QNX UFS partitions..."
    write_partition "${UFS_LUN_DEPLOYDIR}/kernel.part" ${UFS_LUN1_NAME} ${ESP_PARTITION_SIZE_KIB} ${ESP_PARTITION_START_ADDRESS_KIB}
    write_partition ${ROOTFS_EXT4_ARTIFACT_NAME} ${UFS_LUN1_NAME} ${ROOTFS_PARTITION_SIZE_KIB} ${ROOTFS_PARTITION_START_ADDRESS}

    # Cleanup
    rm -f "${UFS_LUN_DEPLOYDIR}/kernel.part"
}
