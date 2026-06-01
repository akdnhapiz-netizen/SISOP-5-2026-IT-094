#!/bin/bash
echo "==> Membangun ISO File..."
mkdir -p isodir/boot/grub
cp osboot/bzImage isodir/boot/
cp osboot/single.gz isodir/boot/
cp osboot/multi.gz isodir/boot/

cat << 'EOF' > isodir/boot/grub/grub.cfg
menuentry "Farewell Party - Single User" {
    linux /boot/bzImage console=ttyS0 console=tty1
    initrd /boot/single.gz
}
menuentry "Farewell Party - Multi User" {
    linux /boot/bzImage console=ttyS0 console=tty1
    initrd /boot/multi.gz
}
EOF

grub-mkrescue -o osboot/farewell.iso isodir
rm -rf isodir
echo "==> OS ISO Bootable (farewell.iso) Selesai Dibuat!"
