SUMMARY = "QNX IFS (Image File System) for GrayVIP"
DESCRIPTION = "Provides QNX IFS file for boot partition"
LICENSE = "CLOSED"

SRC_URI = "${@'file://' + d.getVar('QNX_IFS_PATH') if d.getVar('ENABLE_QNX') == 'true' else ''}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

inherit deploy 

addtask deploy after do_unpack

do_deploy() {
    # Copy to deploy directory
    install -d ${DEPLOYDIR}
    install -m 644 "${WORKDIR}${QNX_IFS_PATH}" ${DEPLOYDIR}/$(basename ${QNX_IFS_PATH})
}

