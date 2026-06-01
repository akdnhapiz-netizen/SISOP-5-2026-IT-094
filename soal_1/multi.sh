#!/bin/bash
mkdir -p multi_fs
cd multi_fs

echo "==> Mengunduh Alpine Mini Rootfs (Built on BusyBox)..."
wget -nc https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-minirootfs-3.19.1-x86_64.tar.gz
tar -xf alpine-minirootfs-*.tar.gz

echo "==> Konfigurasi Hak Akses & Group..."
rm -rf home/*
mkdir -p home/{henn,hann,viii,kids}

# Membuat sistem grup berjenjang untuk memenuhi spesifikasi akses:
cat << 'EOF' >> etc/group
henn:x:1001:
hann:x:1002:henn
viii:x:1003:henn,hann
kids:x:1004:henn,hann,viii
EOF

echo "==> Konfigurasi Users dan Password..."
# Menggunakan openssl untuk generate hash MD5 standar linux
ROOT_PW=$(openssl passwd -1 "root123")
HENN_PW=$(openssl passwd -1 "henn123")
HANN_PW=$(openssl passwd -1 "hann123")
VIII_PW=$(openssl passwd -1 "viii123")
KIDS_PW=$(openssl passwd -1 "kids123")

sed -i "s|^root:.*|root:$ROOT_PW:19700:0:99999:7:::|" etc/shadow

echo "henn:x:1001:1001:Linux User,,,:/home/henn:/bin/sh" >> etc/passwd
echo "hann:x:1002:1002:Linux User,,,:/home/hann:/bin/sh" >> etc/passwd
echo "viii:x:1003:1003:Linux User,,,:/home/viii:/bin/sh" >> etc/passwd
echo "kids:x:1004:1004:Linux User,,,:/home/kids:/bin/sh" >> etc/passwd

echo "henn:$HENN_PW:19700:0:99999:7:::" >> etc/shadow
echo "hann:$HANN_PW:19700:0:99999:7:::" >> etc/shadow
echo "viii:$VIII_PW:19700:0:99999:7:::" >> etc/shadow
echo "kids:$KIDS_PW:19700:0:99999:7:::" >> etc/shadow

echo "==> Terapkan Spesifikasi Permission..."
chown 1001:1001 home/henn && chmod 770 home/henn
chown 1002:1002 home/hann && chmod 770 home/hann
chown 1003:1003 home/viii && chmod 770 home/viii
chown 1004:1004 home/kids && chmod 770 home/kids
chmod 700 root
chmod 777 tmp

echo "==> Setup Package Manager (party)..."
cp sbin/apk sbin/party
# Bypass TLS secara default untuk wget
echo "alias wget='wget --no-check-certificate'" >> etc/profile

echo "==> Setup ASCII Art Banner & Init..."
cat << 'EOF' > etc/profile.d/banner.sh
echo "======================================="
echo "   ___                             _ _ "
echo "  | __|_ _ _ _ _____ __ _____| | | |"
echo "  | _/ _\` | '_/ -_) \ / V / -_) | | |"
echo "  |_|\__,_|_| \___|_\_/\_/\___|_|_| |"
echo "      Farewell Party Modul 5"
echo "======================================="
echo "Welcome, $(whoami)"
EOF
chmod +x etc/profile.d/banner.sh

cat << 'EOF' > init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# NYALAKAN NETWORK INTERFACE SEBELUM MEMINTA IP
ip link set lo up
ip link set eth0 up

# Meminta IP dari QEMU DHCP
udhcpc -i eth0

exec /sbin/getty -n -l /bin/login 38400 tty1
EOF
chmod +x init

echo "==> Membungkus menjadi initramfs multi.gz..."
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../osboot/multi.gz
cd ..
rm -rf multi_fs
echo "==> multi.gz selesai dibuat di osboot!"
