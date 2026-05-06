inherit features_check

REQUIRED_DISTRO_FEATURES = "nxp-cloud-gw"

RDEPENDS:${PN} += "\
    bash \
    ifmetric \
    iproute2 \
    greengrass-bin \
    python3-boto3 \
    aws-iot-device-sdk-python-v2 \
    aws-crt-python \
"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

DEST_DIR = "/opt/${PN}"

do_install:append() {
    install -d ${D}${DEST_DIR}/

    install -m 644 ${CLOUD_GW_SRC_DIR}/ggv2_deployment_configurations.json ${D}${DEST_DIR}/
    install -m 755 ${CLOUD_GW_SRC_DIR}/greengrass_provision.py ${D}${DEST_DIR}/
    install -m 755 ${CLOUD_GW_SRC_DIR}/utils.py ${D}${DEST_DIR}/
}

FILES:${PN} += "${DEST_DIR}"