#!/bin/bash
echo "==> Mengunduh Linux Kernel 6.1.1..."
wget -nc https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.1.tar.xz
tar -xf linux-6.1.1.tar.xz

cd linux-6.1.1
echo "==> Konfigurasi default..."
make defconfig

echo "==> Proses kompilasi dimulai (Menggunakan gcc-12)..."
# Solusi Error: Memaksa make menggunakan gcc-12
make -j$(nproc) CC=gcc-12 HOSTCC=gcc-12

echo "==> Memindahkan bzImage ke osboot..."
cp arch/x86/boot/bzImage ../osboot/bzImage
cd ..
echo "==> Selesai!"
