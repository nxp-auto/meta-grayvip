FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:fsl-grayvip = " file://10-enp0s0f0.network"

do_install:append:fsl-grayvip() {
    install -D -m0644 ${WORKDIR}/10-enp0s0f0.network \
        ${D}${systemd_unitdir}/network/10-enp0s0f0.network
}

FILES:${PN}:append:fsl-grayvip = " ${systemd_unitdir}/network/10-enp0s0f0.network"
