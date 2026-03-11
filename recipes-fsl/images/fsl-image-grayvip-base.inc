# Copyright 2025 NXP

require recipes-fsl/images/fsl-image-vip-base.inc

# Add packages to image
IMAGE_INSTALL:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-eiqa-demos', ' eiqa-runtime-prebuilt eiqa-runtime-prebuilt-firmware ', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-carv', ' carv carv-apps ', '', d)} \
"

# Add the UFS images in the boot partition if GRAYVIP_COHORT6_IMGS_DIR is set.
python() {
    if d.getVar("GRAYVIP_COHORT6_IMGS_DIR") and os.path.exists(d.getVar("GRAYVIP_COHORT6_IMGS_DIR")):
        for i in range(0, int(d.getVar("GRAYVIP_COHORT6_IMGS_COUNT"))):
            d.appendVar("SDCARDIMAGE_BOOT_EXTRA_FILES", f" cohort6-deploy:lun{i}.ufs")
}