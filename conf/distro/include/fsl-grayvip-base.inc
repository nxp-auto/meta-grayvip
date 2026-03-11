require conf/distro/fsl-auto.conf

DISTRO_NAME = "GrayVIP"
DISTRO_VERSION = "${GRAYVIP_RELEASE} (based on Auto Linux BSP ${ALB_RELEASE})"

# Features specific to the GrayVIP distros
DISTRO_FEATURES:append = " grayvip-disable-nxp-switch grayvip-disable-xspi grayvip-disable-can nxp-eiqa-demos nxp-carv "

GRAYVIP_COHORT6_IMGS_DIR ?= ""
GRAYVIP_COHORT6_IMGS_FILENAME ?= "fsl-image-base-${MACHINE}"
GRAYVIP_COHORT6_IMGS_COUNT ?= "2"