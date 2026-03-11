SUMMARY = "Linux BSP UC 1.1.6 UFS images deployment helper"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${FSL_EULA_FILE};md5=${FSL_EULA_FILE_MD5SUM}"

inherit deploy

FILESEXTRAPATHS:prepend := "${GRAYVIP_COHORT6_IMGS_DIR}:"

# Add files to SRC_URI only if GRAYVIP_COHORT6_IMGS_DIR is defined and the path exists.
python() {
    if d.getVar("GRAYVIP_COHORT6_IMGS_DIR") and os.path.exists(d.getVar("GRAYVIP_COHORT6_IMGS_DIR")):
        for i in range(0, int(d.getVar("GRAYVIP_COHORT6_IMGS_COUNT"))):
            image_name = f"{d.getVar('GRAYVIP_COHORT6_IMGS_FILENAME')}.lun{i}.ufs"
            d.appendVar("SRC_URI", f" file://{image_name};unpack=0")
}

S = "${WORKDIR}"
PACKAGES = ""
INHIBIT_PACKAGE_STRIP = "1"

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

# Rename the UFS images to match the U-Boot environment variables.
do_deploy() {
    install -d ${DEPLOYDIR}

    for f in ${S}/${GRAYVIP_COHORT6_IMGS_FILENAME}.lun*.ufs; do
        img_basename=$(basename "$f")
        new_img_basename="${img_basename#${GRAYVIP_COHORT6_IMGS_FILENAME}.}"
        install -m 0644 ${f} ${DEPLOYDIR}/${new_img_basename}
    done
}

addtask do_deploy after do_unpack