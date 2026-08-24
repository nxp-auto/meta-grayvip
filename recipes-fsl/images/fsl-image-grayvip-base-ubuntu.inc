# Copyright 2026 NXP

require recipes-fsl/images/fsl-image-ubuntu-base.bb

# Add packages installed via APT to image
APTGET_EXTRA_PACKAGES:append = " \
    lvm2 \
    curl \
    python3-pip \
    openssh-server \
"

# Add packages to image
IMAGE_INSTALL:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-eiqa-demos', ' packagegroup-eiqa-base ', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-ara2', ' packagegroup-ara2 ', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-carv', ' carv carv-apps ', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'nxp-motionwise', ' motionwise-communication-examples', '', d)} \
"

IMAGE_INSTALL:append:fsl-grayvip-ai = " \
    nxp-ufs-unify \
"

# The Ubuntu openssh-server post-install would normally create the host keys,
# but that step runs inside the aptget pseudo-chroot and is skipped, so the
# image ships without /etc/ssh/ssh_host_* and sshd refuses to start on the
# target.
#
# Add a small, self-contained oneshot unit that only generates the keys when
# they are missing, and pull it in as a dependency of ssh via an additive
# .wants symlink. Nothing the distro ships is modified.
IMAGE_PREPROCESS_COMMAND:append = " do_prepare_openssh_server; "
fakeroot do_prepare_openssh_server() {
    if [ ! -f "${APTGET_CHROOT_DIR}/usr/lib/systemd/system/ssh.service" ]; then
        return 0
    fi

    install -d "${APTGET_CHROOT_DIR}/etc/systemd/system"
    cat >"${APTGET_CHROOT_DIR}/etc/systemd/system/ssh-hostkeys.service" <<EOF
[Unit]
Description=Generate OpenSSH host keys if missing
Documentation=man:ssh-keygen(1)
ConditionPathExistsGlob=|!/etc/ssh/ssh_host_*_key
Before=ssh.service
DefaultDependencies=no
After=local-fs.target
RequiresMountsFor=/etc/ssh

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/ssh-keygen -A

[Install]
WantedBy=ssh.service
EOF

    # Enable it additively (no edit to ssh.service): a .wants symlink makes
    # systemd pull ssh-hostkeys.service in whenever ssh.service is started.
    install -d "${APTGET_CHROOT_DIR}/etc/systemd/system/ssh.service.wants"
    ln -sf ../ssh-hostkeys.service \
        "${APTGET_CHROOT_DIR}/etc/systemd/system/ssh.service.wants/ssh-hostkeys.service"
}