require conf/distro/fsl-auto.conf

DISTRO_NAME = "GrayVIP"
DISTRO_VERSION = "${GRAYVIP_RELEASE} (based on Auto Linux BSP ${ALB_RELEASE})"

# Replace UFS Linux Boot Image with QNX Boot Image.
# Possible values: "true" - Enabled, "false" - Disabled. Default: "false" - Disabled.
ENABLE_QNX ?= "false"