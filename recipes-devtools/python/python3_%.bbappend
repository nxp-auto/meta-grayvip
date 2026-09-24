# Copyright 2026 NXP

# Suppress the file-rdeps QA check for the version-suffixed Python helper
# scripts when building against an Ubuntu 22.04 userland.
#
# Background
# ----------
# poky scarthgap builds Python 3.12. The helper scripts in python3-pydoc,
# python3-2to3 and python3-idle are installed with a version suffix and carry
# a "#!/usr/bin/python3.12" shebang:
#
#     /usr/bin/pydoc3.12
#     /usr/bin/2to3-3.12
#     /usr/bin/idle3.12
#
# The shebang creates a file-level runtime dependency on /usr/bin/python3.12.
# Normally that file is supplied by python3-core.
#
# On this BSP, python3 and python3-core are listed in
# DISTRO_NEVER_WRITE_PACKAGE (meta-alb-sdk conf/machine/include/ubuntubasics.inc),
# because the Ubuntu rootfs already provides a Python interpreter and the Yocto
# one must not overwrite it. As a result nodistropackage.inc rewrites the
# RDEPENDS of these packages to point at the Ubuntu rootfs provider named in
# DISTRO_DEFAULT_RPROVIDER, that is ubuntu-base.
#
# With UBUNTU_TARGET_VERSION = "22.04.1" the ubuntu-base package only supplies
# /usr/bin/python3.10, so the dependency on /usr/bin/python3.12 cannot be
# satisfied by any provider and do_package_qa fails the file-rdeps check.
#
# This is a genuine interpreter version mismatch, not a metadata problem:
# Ubuntu 22.04 ships Python 3.10 while poky scarthgap builds Python 3.12.
# Adding the package names to APTGET_RPROVIDES does not help, because that
# declares package-level RPROVIDES while file-rdeps resolves a file path.
#
# KNOWN LIMITATION
# ----------------
# Suppressing the check does not make these scripts work. If the packages are
# installed on a 22.04 rootfs, running /usr/bin/pydoc3.12, /usr/bin/2to3-3.12
# or /usr/bin/idle3.12 fails with a bad interpreter error, because no
# /usr/bin/python3.12 exists. Use the unsuffixed pydoc3, 2to3 and idle3 entry
# points from the Ubuntu python3 packages instead.
#
# As of this change the impact is latent rather than actual: python3-pydoc,
# python3-2to3 and python3-idle are not present in the fsl-image-ubuntu-base
# image manifest, so nothing on the shipped rootfs invokes these scripts. The
# packages are only produced by the python3 recipe, which is what made
# do_package_qa fail. If a future image or packagegroup adds any of them to
# an Ubuntu 22.04 target, revisit this: the scripts would then be installed
# and would fail at runtime.
#
# The suppression is deliberately conditional on the Ubuntu 22.04 userland.
# Moving to Ubuntu 24.04, which ships Python 3.12 and matches the poky
# scarthgap toolchain, removes the mismatch entirely. In that case the
# condition below evaluates to empty and the file-rdeps check stays fully
# enabled, so real missing dependencies are still reported.
PYTHON312_SHEBANG_QA_SKIP = "${@oe.utils.conditional('UBUNTU_TARGET_BASEVERSION', '22.04', 'file-rdeps', '', d)}"

INSANE_SKIP:${PN}-pydoc += "${PYTHON312_SHEBANG_QA_SKIP}"
INSANE_SKIP:${PN}-2to3 += "${PYTHON312_SHEBANG_QA_SKIP}"
INSANE_SKIP:${PN}-idle += "${PYTHON312_SHEBANG_QA_SKIP}"
