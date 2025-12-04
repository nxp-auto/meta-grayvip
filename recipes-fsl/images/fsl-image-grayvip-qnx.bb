# Copyright 2025 NXP

DESCRIPTION = "GrayVIP Yocto Image with QNX support"
LICENSE = "EULA"
LIC_FILES_CHKSUM = "file://${FSL_EULA_FILE};md5=${FSL_EULA_FILE_MD5SUM}"

require recipes-fsl/images/fsl-image-grayvip-base.inc

# Force QNX configuration - always enable QNX for this image
# Remove standard UFS class and use QNX UFS class
IMAGE_CLASSES:remove = "image_types_fsl_ufs"
IMAGE_CLASSES:append = " image_types_fsl_qnx_ufs"

IMAGE_CLASSES:remove = "image_types_fsl_sdcard"
IMAGE_CLASSES:append = " image_types_fsl_qnx_sdcard"
