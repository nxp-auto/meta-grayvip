#
# Copyright 2024-2025 NXP
#

DESCRIPTION = "GrayVIP Yocto Image"
LICENSE = "EULA"
LIC_FILES_CHKSUM = "file://${FSL_EULA_FILE};md5=${FSL_EULA_FILE_MD5SUM}"

require recipes-fsl/images/fsl-image-vip-base.inc

# Add packages to image
IMAGE_INSTALL:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-eiqa-demos', ' eiqa-runtime-prebuilt eiqa-runtime-prebuilt-firmware ', '', d)} \
"
# Use QNX-enabled UFS class when QNX is enabled, otherwise use standard UFS class
# Use IMAGE_CLASSES - Remove standard UFS and add QNX UFS when enabled
IMAGE_CLASSES:remove = "${@oe.utils.vartrue('ENABLE_QNX', 'image_types_fsl_ufs', '', d)}"
IMAGE_CLASSES:append = "${@oe.utils.vartrue('ENABLE_QNX', ' image_types_fsl_qnx_ufs', '', d)}"
