require conf/distro/fsl-auto.conf

DISTRO_NAME = "GrayVIP"
DISTRO_VERSION = "${GRAYVIP_RELEASE} (based on Auto Linux BSP ${ALB_RELEASE})"

# Override SDK_VERSION to prevent shell syntax errors from spaces/parentheses in DISTRO_VERSION
SDK_VERSION = "${GRAYVIP_RELEASE}"

# Features specific to the GrayVIP distros
DISTRO_FEATURES:append = " \
    grayvip-disable-nxp-switch \
    grayvip-disable-xspi \
    grayvip-disable-can \
    nxp-eiqa-demos \
    nxp-carv \
    nxp-motionwise \
    nxp-ufs-unify \
"

