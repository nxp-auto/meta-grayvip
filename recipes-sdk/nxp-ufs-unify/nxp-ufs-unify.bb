SUMMARY = "Include scripts in linux image for mounting UFS LUNs as a single logical volume"
DESCRIPTION = "Identify the UFS LUNs, formats and mounts them as a single logical volume to /data"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} = "lvm2 e2fsprogs util-linux-wipefs util-linux-blkid udev"

inherit systemd

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "prepare-ufs.service data.mount"

SRC_URI = " \
    file://nxp-ufs-unify.sh \
    file://prepare-ufs.service \
    file://data.mount \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/nxp-ufs-unify.sh ${D}${bindir}/nxp-ufs-unify.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/prepare-ufs.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/data.mount ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    ${bindir}/nxp-ufs-unify.sh \
    ${systemd_system_unitdir}/prepare-ufs.service \
    ${systemd_system_unitdir}/data.mount \
"