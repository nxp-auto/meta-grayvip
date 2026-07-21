FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}/build:"

# Add the required kernel configs for GrayVIP
DELTA_KERNEL_DEFCONFIG:append = " \
    grayvip.cfg \
"

SRC_URI:append= " \
    file://grayvip.cfg \
"

SRC_URI:append:s32n79sim = " \
    file://s32n79-simulator-no-nxp-switch.patch \
    file://s32n79-simulator-disable-xspi.patch \
    file://s32n79-simulator-disable-can.patch \
"