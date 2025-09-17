FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}/build:"

SRC_URI:append= " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'grayvip-disable-nxp-switch', 'file://s32n79-simulator-no-nxp-switch.patch', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'grayvip-disable-xspi', 'file://s32n79-simulator-disable-xspi.patch', '', d)} \
"