# Copyright 2025-2026 NXP

FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

FILESEXTRAPATHS:prepend := "${@bb.utils.contains('DISTRO_FEATURES', 'ddr_intrlv', '${THISDIR}/dts-ddr/${DDR_ECC_VARIANT}:', '', d)}"
