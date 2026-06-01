#!/bin/bash
mkdir -p single_fs
cd single_fs

echo "==> Membuat struktur direktori..."
mkdir -p bin dev proc sys etc tmp root

echo "==> Download & Build BusyBox..."
wget -nc https://busybox.net/downloads/busybox-1.36.1.tar.bz2
tar -xf busybox-1.36.1.tar.bz2
cd busybox-1.36.1
make defconfig
# Buat Busybox jadi static agar tidak butuh library eksternal
sed -i 's/^.*CONFIG_STATIC.*/CONFIG_STATIC=y/' .config
make -j$(nproc) CC=gcc-12 HOSTCC=gcc-12
make install CONFIG_PREFIX=../
cd ..

echo "==> Membuat Init script..."
cat << 'EOF' > init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
echo "Welcome to Single User Mode (Root Only)"
exec /bin/sh
EOF
chmod +x init

echo "==> Membungkus menjadi initramfs..."
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../osboot/single.gz
cd ..
rm -rf single_fs
echo "==> single.gz selesai dibuat di osboot!"
