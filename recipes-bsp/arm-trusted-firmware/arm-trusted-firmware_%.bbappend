FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI:append= " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'grayvip-ufs-virtual-interface', 'file://s32n79-simulator-ufshci0-okay.patch', '', d)} \
"
