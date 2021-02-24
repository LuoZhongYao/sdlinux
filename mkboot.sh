#!/bin/bash
set -x
base=zboot
export LD_LIBRARY_PATH=$HOME/.local/lib

function mkimg()
{
    cd ${base}
    mkbootfs ramdisk | gzip > ${base}.img-ramdisk.gz
    mkbootimg \
        --kernel ${base}.img-zImage             \
        --ramdisk ${base}.img-ramdisk.gz        \
        --cmdline "$(< ${base}.img-cmdline)"    \
        --base "0x$(< ${base}.img-base)"        \
        --second ${base}.img-second             \
        --pagesize "$(< ${base}.img-pagesize)"  \
        --second_offset 0x$(< ${base}.img-secondoff) \
        --ramdisk_offset 0x$(< ${base}.img-ramdiskoff) \
        --kernel_offset 0x$(< ${base}.img-kerneloff) \
        --tags_offset 0x$(< ${base}.img-tagsoff) \
        --hash $(< ${base}.img-hash) \
        --output ../boot.img
}

case $1 in
    --dtb)
        dtc -Idts -Odtb ${base}.dts > ${base}/${base}.img-second
        mkimg
        ;;
    --dts)
        dtc -Idtd -Odts ${base}/${base}.img-second > ${base}.dts
        ;;
    -d)
        rm -rf  ${base}
        mkdir -p ${base}/ramdisk
        cd ${base}
        unpackbootimg -i ../${base}.img
        cd ramdisk
        gzip -dc ../${base}.img-ramdisk.gz | cpio -imd
        ;;
    -c)
        mkimg
        ;;
esac
