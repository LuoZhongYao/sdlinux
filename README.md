# sdlinux
Manually create linux boot SD card for ARM platform

## Use orangepi win Plus

### Compile U-boot

Read board/sunxi/README.sunxi64
```shell
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
make orangepi_win_defconfig
make
```

### Complie kernel

```shell
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
make defconfig
make
```

### SD card partition

```shell
sfdisk --delete /dev/sdc
sfdisk /dev/sdc << EOF
1M,128M,L,*
,,L
EOF
mkfs.ext4 /dev/sdc1
mkfs.ext4 /dev/sdc2
blockdev /dev/sdc
```

### Flash u-boot

```shell
dd if=u-boot-sunxi-with-spl.bin bs=1024 seek=8
```

### boot

```shell
cat << EOF > boot.cmd
setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait panic=10 rootfstype=ext4 rw ${extra}
ext4load mmc 0 ${kernel_addr_r} Image
ext4load mmc 0 ${fdt_addr_r} sun50i-a64-orangepi-win.dtb
booti ${kernel_addr_r} - ${fdt_addr_r}
EOF

mount /dev/sdc1 /mnt/boot/
cp ${kernel}/arch/arm64/Image /mnt/boot/
cp ${kernel}/arch/arm64/dtsallwinner/sun50i-a64-orangepi-win.dtb  /mnt/boot/
mkimage -C none -A arm64 -T script -d boot.cmd /mnt/boot/boot.scr
```

### Create rootfs

```shell
wget https://dl.fedoraproject.org/pub/fedora/linux/releases/32/Container/aarch64/images/Fedora-Container-Base-32-1.6.aarch64.tar.xz
mkdir fedora
mount /dev/sdc2 /mnt/rootfs/
tar xf Fedora-Container-Base-32-1.6.aarch64.tar.xz -C fedora/
find fedora/ -name 'layer.tar' -exec tar xf {} -C /mnt/rootfs \;
cp /usr/bin/qemu-static-aarch64 /mnt/usr/bin/
mount -o bind /dev /mnt/dev
mount -o bind /dev/pts /mnt/rootfs/dev/pts
mount -o bind /proc /mnt/rootfs/proc
mount -o bind /sys /mnt/rootfs/sys
cp /etc/resolv.conf /mnt/rootfs/etc
chroot /mnt/rootfs /bin/bash
dnf update
dnf install systemd-udev
dnf autoremove
dnf clean all
passwd						# Set the root password, otherwise you may not be able to log in
# No need
# systemctl unmask console-getty
# systemctl enable console-getty
# systemctl set-default getty
exit
umount /mnt/rootfs/dev/pts
umount /mnt/rootfs/dev
umount /mnt/rootfs/sys
umount /mnt/rootfs/proc
umount /mnt/rootfs
umount /mnt/boot
```
