SUMMARY = "Cloud Gateway Provisioning"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${FSL_EULA_FILE};md5=${FSL_EULA_FILE_MD5SUM}"

require recipes-sdk/cloud-gw/cloud-gw.inc

CLOUD_GW_SRC_DIR = "${S32N_SDK_DIR}/common/cloud_gw"
