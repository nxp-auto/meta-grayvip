SUMMARY = "QNX IFS (Image File System) for GrayVIP"
DESCRIPTION = "Provides QNX IFS file for boot partition"
LICENSE = "CLOSED"

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

SRC_URI:append:fsl-grayvip-qnx = " \
    ${@f"file://{d.getVar('QNX_IFS_PATH')}" if (d.getVar('PREFERRED_VERSION_%s' % d.getVar('PN')) or d.getVar('PV')) == d.getVar('PV') else ''} \
"

inherit deploy

addtask deploy after do_unpack

do_deploy() {
    # Copy to deploy directory
    install -d ${DEPLOYDIR}
    install -m 644 "${WORKDIR}/${QNX_IFS_PATH}" "${DEPLOYDIR}/${QNX_KERNEL_IMAGE}"

    ln -sf ${QNX_KERNEL_IMAGE} "${DEPLOYDIR}/${QNX_KERNEL_IMAGE}-${MACHINE}.bin"
}
