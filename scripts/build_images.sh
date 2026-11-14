#!/bin/sh -e

CHROOT=${CHROOT=$(pwd)/rootfs}

# package rootfs
rm -f rootfs.raw boot.raw
mkdir -p files mnt

# create boot
# 本机 stock GPT 的 boot 分区只有 16MB（原仓库默认 64MB）。
# 注意：rootfs.tgz 里的 ./boot/dtbs 是全高通平台的设备树（几百 MB），
# 不能整目录解出来，只挑内核 + extlinux + 本机两个 dtb。
truncate -s 16777216 boot.raw
mkfs.ext2 -F boot.raw
mount boot.raw mnt
tar xf rootfs.tgz -C mnt --strip-components=2 \
    ./boot/vmlinuz \
    ./boot/extlinux \
    ./boot/dtbs/qcom/msm8916-thwc-ufi001c.dtb \
    ./boot/dtbs/qcom/msm8916-mtp.dtb
umount mnt

# create root img
# 1.5GB，烧到 stock GPT 的 userdata 分区（2590MB），首启后 resize2fs 撑满
truncate -s 1610612736 rootfs.raw
mkfs.ext4 -F rootfs.raw
mount rootfs.raw mnt
tar xpf rootfs.tgz -C mnt --exclude='./boot/*' --exclude='./root/*' --exclude='./dev/*'

# install gt
cp -a dist/* mnt

umount mnt

# create sparse android images
img2simg rootfs.raw files/rootfs.bin
img2simg boot.raw files/boot.bin
