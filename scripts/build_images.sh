#!/bin/sh -e

CHROOT=${CHROOT=$(pwd)/rootfs}

# package rootfs
rm -f rootfs.raw boot.raw
mkdir -p files mnt

# create boot
# 本机 stock GPT 的 boot 分区只有 16MB（原仓库默认 64MB），
# 所以 boot 镜像按 16MB 生成，并且下面会把 220 个 dtb 裁到只剩本机那一个。
truncate -s 16777216 boot.raw
mkfs.ext2 -F boot.raw
mount boot.raw mnt
tar xf rootfs.tgz -C mnt ./boot --exclude='./boot/linux.efi' --strip-components=2
find mnt/dtbs -type f ! -name 'msm8916-thwc-ufi001c.dtb' ! -name 'msm8916-mtp.dtb' -delete 2>/dev/null || true
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
