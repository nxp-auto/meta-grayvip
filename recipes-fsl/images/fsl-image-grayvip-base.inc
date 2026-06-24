# Copyright 2025-2026 NXP

require recipes-fsl/images/fsl-image-vip-base.inc

# Add packages to image
IMAGE_INSTALL:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-eiqa-demos', ' packagegroup-eiqa-base ', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-ara2', ' packagegroup-ara2 ', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-carv', ' carv carv-apps ', '', d)} \
"
