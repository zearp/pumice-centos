#!/bin/bash
#
# pumice-centos config.sh — Fedora-parity build
#
set -euxo pipefail

# functions
#
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

# make sure the crb repo is enabled
#
dnf -y config-manager --set-enabled crb

# selinux, needed for kde and maybe others
#
setsebool -P selinuxuser_execmod 1

# set a hostname
#
echo "pumice" > /etc/hostname

# clear machine id
#
truncate -s 0 /etc/machine-id

# grub
#
echo "GRUB_DEFAULT=saved" >> /etc/default/grub

# services
#
systemctl enable systemd-oomd.service
systemctl enable systemd-resolved.service
systemctl mask kdump.service

# persistent logs
#
mkdir -p /var/log/journal

# clear root password
#
passwd -d root
passwd -l root

# we are live
#
echo 'livesys_session="gnome"' > /etc/sysconfig/livesys
sed -i -e "s/org.fedoraproject.AnacondaInstaller/anaconda/" -e "s/NoDisplay=true/NoDisplay=false/" /usr/share/applications/liveinst.desktop

# set default boot target (gui or cli)
#
systemctl set-default graphical.target
#systemctl set-default multi-user.target

# apply custom gnome stuff in /etc/dconf/db/local.d/99-pumice
#
dconf update

# setup flathub repo
#
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# install flatpak apps
#
flatpak -y install org.gnome.Weather
#flatpak -y install io.gitlab.librewolf-community
# this should not be needed but sometimes it does find updates
flatpak -y update && flatpak -y remove --unused

# rpm fusion
#
dnf -y install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm
dnf -y install --nogpgcheck https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm
dnf -y install rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted

# multimedia
#
dnf -y install libdvdcss
dnf -y swap ffmpeg-free ffmpeg --allowerasing
dnf -y install @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# amd media driver
#dnf -y install mesa-va-drivers-freeworld

# intel media driver
dnf -y install intel-media-driver

# older intel needs this instead
#dnf -y install libva-intel-driver

# nvidia
#dnf -y install install libva-nvidia-driver

dnf -y update @core

# setup brave origin
#sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
#sudo dnf install brave-origin

# dnf stuff
#
dnf -y config-manager --set-disabled elrepo elrepo-extras elrepo-kernel
dnf -y config-manager --set-enabled crb epel
dnf -y --refresh update && dnf clean all && dnf makecache

exit 0
