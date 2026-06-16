# Copyright 2026 NXP
SUMMARY = "MotionWise Communication Experience Kit"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${FSL_EULA_FILE};md5=${FSL_EULA_FILE_MD5SUM}"

inherit features_check
REQUIRED_DISTRO_FEATURES = "nxp-motionwise"

SRC_URI = " \
    file://configRefApp1_enp0s0f0.xml \
    file://env-configRefApp1_enp0s0f0.sh \
"

python () {
    # Exit immediately if the distro feature is not enabled.
    if not bb.utils.contains('DISTRO_FEATURES', 'nxp-motionwise', True, False, d):
        return

    # Use the URL to the MotionWise Communication Experience Kit if it set.
    url = d.getVar('MOTIONWISE_COMMUNICATION_EK_URL')
    if url:
        d.appendVar('SRC_URI', f' {url};subdir={d.getVar("MOTIONWISE_COMMUNICATION_EK")}')
        return

    # Use the path to the local archive otherwise.
    archive_path = d.getVar('MOTIONWISE_COMMUNICATION_EK_ARCHIVE')
    if archive_path:
        d.appendVar('SRC_URI', f' file://{archive_path};subdir={d.getVar("MOTIONWISE_COMMUNICATION_EK")}')
        return

    # Fallback to using the path to a local dir containing the EK.
    local_dir = d.getVar("MOTIONWISE_COMMUNICATION_EK_DIR")
    if os.path.dirname(local_dir):
        d.prependVar('FILESEXTRAPATHS', f'{os.path.dirname(local_dir)}:')
    basename = os.path.basename(local_dir)
    d.appendVar('SRC_URI', f' file://{basename}')
    d.setVar('MOTIONWISE_COMMUNICATION_EK', f'{basename}')
}

MOTIONWISE_COMMUNICATION_EK ?= "ZAEK_V${PV}"
S = "${WORKDIR}/${MOTIONWISE_COMMUNICATION_EK}/product_package/ZettaAuto/MPU"

# Overwrite the PACKAGES variable to exclude ${PN}-dev and ${PN}-staticdev; place the prebuilt
# .so and .a libraries in the default package.
PACKAGES = "${PN}-src ${PN}-dbg ${PN}-doc ${PN}-locale ${PACKAGE_BEFORE_PN} ${PN}-examples ${PN}"
# Workaround: Ignore dependencies checks for prebuilt binaries. These shall be removed once the
#             EK includes properly versioned SO libs.
SKIP_FILEDEPS:${PN} = "1"
INSANE_SKIP:${PN} += " file-rdeps staticdev"
SKIP_FILEDEPS:${PN}-examples = "1"
INSANE_SKIP:${PN}-examples += " file-rdeps staticdev"

RDEPENDS:${PN}-examples += "${PN}"
RDEPENDS:${PN} += "bash libcrypto libssl"

do_fetch[depends] += "unzip-native:do_populate_sysroot"
do_configure[noexec] = "1"
do_compile[noexec] = "1"

EXAMPLES_DIR = "/opt/${PN}/examples"

do_install() {
    install -d ${D}${libdir}
    cp -r ${S}/linux-prebuilt/${HOST_ARCH}/lib/lib*.so* ${D}${libdir}/
    cp -r ${S}/linux-prebuilt/${HOST_ARCH}/lib/lib*.a ${D}${libdir}/

    install -d ${D}${includedir}
    cp -r ${S}/linux-prebuilt/${HOST_ARCH}/include/* ${D}${includedir}/

    install -d ${D}${bindir}
    install -m 0755 ${S}/linux-prebuilt/${HOST_ARCH}/bin/* ${D}${bindir}/

    install -d ${D}${EXAMPLES_DIR}
    install -m 0755 ${S}/examples/bin/linux/${HOST_ARCH}/* ${D}${EXAMPLES_DIR}/

    install -d ${D}${sysconfdir}/${PN}
    install -m 0644 ${WORKDIR}/configRefApp1_enp0s0f0.xml ${D}${sysconfdir}/${PN}

    install -d ${D}${sysconfdir}/profile.d
    install -m 0755 ${WORKDIR}/env-configRefApp1_enp0s0f0.sh ${D}${sysconfdir}/profile.d/
}

FILES:${PN} += "${bindir}"
FILES:${PN} += "${libdir}"
FILES:${PN} += "${includedir}"
FILES:${PN}-examples += "${EXAMPLES_DIR} ${sysconfdir}"
