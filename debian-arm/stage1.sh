#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace

# Based on https://github.com/golang/build/blob/master/env/linux-arm-qemu/Dockerfile
#
# Original copyright:
# Copyright 2014 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
#
# Original LICENSE file:
# Copyright (c) 2009 The Go Authors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

export IMG_BLOCK_SIZE=4096
export IMG_BLOCK_COUNT=460800
export IMG_INODE_COUNT=300000
export DEBIAN_FRONTEND=noninteractive

REBUILD_KERNEL=y
if [ -f /vmlinuz ]; then
    echo Not building the kernel
    REBUILD_KERNEL=
else
    echo Will build the kernel
fi

# TBD: is multiarch/emdebian stuff needed if we don't compile the kernel?

apt-get update
apt-get install -y curl openssh-client

#curl http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
# echo 'deb http://emdebian.org/tools/debian/ jessie main' >/etc/apt/sources.list.d/crosstools.list

mkdir /arm

# busybox-static is needed for initrd
debootstrap --arch=armhf --foreign --include=busybox-static,curl,ca-certificates,strace,gcc,libc6-dev,gdb,lsof,psmisc,netbase,ifupdown,iproute,openssh-client,openssh-server,iputils-ping,wget,udev,net-tools,ntpdate,ntp,vim,nano,less,tzdata,module-init-tools,usbutils,i2c-tools,udhcpc,curl,htop,pv jessie /arm/root

# make initrd (based on http://jootamam.net/howto-initramfs-image.htm)
for dir in bin sbin etc proc sys newroot usr/bin usr/sbin; do
    mkdir -p "/initramfs/${dir}"
done
touch /initramfs/etc/mdev.conf
# extract busybox from archive
dpkg-deb --fsys-tarfile /arm/root/var/cache/apt/archives/busybox-static_*.deb | tar -C /initramfs/ -xv ./bin/busybox
chmod +x /initramfs/bin/busybox
ln -s busybox /initramfs/bin/sh
cp /init /initramfs/init
chmod +x /initramfs/init
(cd /initramfs && find . | cpio -H newc -o) | gzip > /initrd
rm -rf /initramfs

# Script to finish off the debootstrap installation, config and key files
mv /stage2.sh /arm/root
ssh-keygen -N "" -f /qemu_key
cp /qemu_key.pub /arm/root
cp -a /etc/ssh/ssh_config /arm/root

# Setup networking.
echo -e "auto lo\niface lo inet loopback\nauto eth0\niface eth0 inet dhcp" > /arm/root/etc/network/interfaces

# Tune systemd.
echo -e "[Journal]\nForwardToConsole=yes" > /arm/root/etc/systemd/journald.conf

# Make filesystem image
genext2fs -d /arm/root -B ${IMG_BLOCK_SIZE} -b ${IMG_BLOCK_COUNT} -N ${IMG_INODE_COUNT} -m 0 /arm/root.img

# Remove rootfs files
rm -rf /arm/root

# convert ext2 -> ext3 -> ext4
/sbin/tune2fs -j /arm/root.img
/sbin/fsck.ext3 -yfD /arm/root.img || true
/sbin/tune2fs -O extents,uninit_bg,dir_index /arm/root.img
/sbin/fsck.ext4 -yfD /arm/root.img || true

# Make sure we have proper kernel
if [[ ${REBUILD_KERNEL} ]]; then
    # Build a kernel. We're building here because we need a recent version for
    # systemd to boot, and the binary ones in debian's repositories have a lot
    # of needed components as modules (filesystem/sata drivers). It's just
    # simpler to build a kernel than it is cross generate an initrd with
    # the right bits in.
    # TODO: check hash
    wget -O /usr/src/linux-3.16.55.tar.xz https://cdn.kernel.org/pub/linux/kernel/v3.x/linux-3.16.55.tar.xz
    tar xfv /usr/src/linux-3.16.55.tar.xz -C /usr/src/
    mv /kernel_config /usr/src/linux-3.16.55/.config
    cd /usr/src/linux-3.16.55
    ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make -j$(grep -c ^processor /proc/cpuinfo) zImage
    cp /usr/src/linux-3.16.55/arch/arm/boot/zImage /arm/vmlinuz
    rm -rf /usr/src/linux-3.16.55
else
    # use prebuilt kernel
    mv /vmlinuz /arm/vmlinuz
    mv /initrd /arm/initrd
fi

# Run stage2.sh script in the VM
qemu-system-arm -M vexpress-a9 \
                -cpu cortex-a9 \
                -nographic \
                -no-reboot \
                -sd /arm/root.img \
                -kernel /arm/vmlinuz \
                -initrd /initrd \
                -append "console=ttyAMA0"

# Make sure the image doesn't contain errors
fsck.ext4 -yf /arm/root.img

# Generate slimmer qcow2 image
qemu-img convert -O qcow2 -p /arm/root.img /arm/root.qcow2
rm /arm/root.img

# Set owner
chmod 600 /qemu_key

# set up ssh client
cat >>/etc/ssh/ssh_config <<END
Host qemu
  User root
  Hostname localhost
  Port 20022
  CheckHostIP no
  StrictHostKeyChecking no
  IdentityFile /qemu_key
  IdentitiesOnly yes
END
