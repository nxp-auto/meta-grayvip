#
# Copyright 2024-2025 NXP
#

DESCRIPTION = "GrayVIP Yocto Image"

require recipes-fsl/images/fsl-image-vip-base.inc
IMAGE_INSTALL:append= " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-eiqa-demos', ' eiqa-runtime-prebuilt eiqa-runtime-prebuilt-firmware ', '', d)} \
"