# Copyright 2025-2026 NXP

require recipes-fsl/images/fsl-image-vip-base.inc

# Add packages to image
IMAGE_INSTALL:append = " \
    lvm2 \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-eiqa-demos', ' packagegroup-eiqa-base ', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-ara2', ' packagegroup-ara2 ', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-carv', ' carv carv-apps ', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-motionwise', ' motionwise-communication-examples', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-cloud-gw', ' cloud-gw ', '', d)} \
"

IMAGE_INSTALL:append:fsl-grayvip-ai = " \
    nxp-ufs-unify \
"

# Extra disk space required by Greengrass v2 when "nxp-cloud-gw" is enabled.
IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains('DISTRO_FEATURES', 'nxp-cloud-gw', ' + 262144', '', d)}"
