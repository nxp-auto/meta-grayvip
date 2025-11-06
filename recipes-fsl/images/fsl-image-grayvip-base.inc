# Copyright 2025 NXP

require recipes-fsl/images/fsl-image-vip-base.inc

# Add packages to image
IMAGE_INSTALL:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-eiqa-demos', ' eiqa-runtime-prebuilt eiqa-runtime-prebuilt-firmware ', '', d)} \
"
