#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos

#dnf5 install -y virt-install

dnf5 install -y \
  kernel-devel-matched \
  gcc \
  make \
  perl

echo -e '#!/bin/sh\nexit 0' > /sbin/vboxconfig
chmod +x /sbin/vboxconfig

curl -L 'https://download.virtualbox.org/virtualbox/7.1.10/VirtualBox-7.1-7.1.10_169112_fedora40-1.x86_64.rpm' > vbox.rpm
dnf5 install -y vbox.rpm || true


cat > /etc/systemd/system/vbox-init.service <<'EOF'
[Unit]
Description=Build VirtualBox kernel modules on first boot
After=network.target
ConditionPathExists=!/lib/modules/$(uname -r)/extra/vboxdrv.ko

[Service]
Type=oneshot
ExecStart=/sbin/vboxconfig

[Install]
WantedBy=multi-user.target
EOF

ln -s /etc/systemd/system/vbox-init.service /etc/systemd/system/multi-user.target.wants/vbox-init.service

cat > /etc/systemd/system/akmods-init.service <<'EOF'
[Unit]
Description=Build VirtualBox kernel modules on first boot
After=network.target
ConditionPathExists=!/lib/modules/$(uname -r)/extra/vboxdrv.ko

[Service]
Type=oneshot
ExecStart=/usr/bin/akmods --force && /usr/bin/modprobe vboxdrv

[Install]
WantedBy=multi-user.target
EOF

ln -s /etc/systemd/system/akmods-init.service /etc/systemd/system/multi-user.target.wants/akmods-init.service


# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
