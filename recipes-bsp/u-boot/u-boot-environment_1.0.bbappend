# Copyright 2025 NXP

# use u-boot-flashenv.txt file from grayvip-qnx dir when ENABLE_QNX is true
FILESEXTRAPATHS:prepend := "${@oe.utils.vartrue('ENABLE_QNX', '${THISDIR}/${BPN}/grayvip-qnx:', '', d)}"
# re-execute do_fetch and do_unpack if ENABLE_QNX changes
do_fetch[vardeps] += " ENABLE_QNX"
do_unpack[vardeps] += "ENABLE_QNX"