#!/bin/sh -e

make -C src/qhypstub CROSS_COMPILE=aarch64-linux-gnu-

# patch to reduce mmc speed as some boards have intermittent failures when
# inititalizing the mmc (maybe due to using old/recycled flash chips)
echo 'DEFINES += USE_TARGET_HS200_CAPS=1' >> src/lk2nd/project/lk1st-msm8916.mk

# 本机（3051f422 / UFI-001C-LOCAL）出厂设备树是通用 512MB MTP，
# 所以 lk1st 仍然 bundle msm8916-512mb-mtp.dtb（内存 512MB 必须匹配），
# 但把 compatible 改成 thwc,ufi001c，让 lk2nd 挑 thwc-ufi001c 的
# 内核设备树去初始化 LED / USB。
make -C src/lk2nd LK2ND_BUNDLE_DTB="msm8916-512mb-mtp.dtb" LK2ND_COMPATIBLE="thwc,ufi001c" \
    TOOLCHAIN_PREFIX=arm-none-eabi- lk1st-msm8916

# test sign
mkdir -p files
src/qtestsign/qtestsign.py hyp src/qhypstub/qhypstub.elf \
    -o files/hyp.mbn
src/qtestsign/qtestsign.py aboot src/lk2nd/build-lk1st-msm8916/emmc_appsboot.mbn \
    -o files/aboot.mbn
