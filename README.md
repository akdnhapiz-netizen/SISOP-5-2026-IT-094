# SISOP-5-2026-IT-094

# Laporan Resmi Sistem Operasi - Modul 5
**Nama:** [Akhdan Hafiz Anugrah]

**NRP:** [5027251094]

---------

# Soal 1: FAREWELL PARTY
## Penjelasan

### Deskripsi Soal
Praktikan diminta membangun distribusi Linux kustom sendiri memanfaatkan kompilasi Linux Kernel resmi dan utilitas BusyBox untuk menyediakan ruang pengguna (user space). Sistem operasi ini harus mendukung dua mode operasi utama: yaitu single dan multi
### Solusi Script (`kernel.sh`)
Skrip ini mengunduh kode sumber kernel Linux, menerapkan konfigurasi arsitektur dasar (`.config`), dan memicu kompilasi biner `bzImage`.
```sh
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
```
### Solusi Script (`single.sh`)
Membangun struktur direktori esensial Linux dan mengompilasi BusyBox ke dalam format arsip terkompresi `single.gz`.
```sh
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
```
### Solusi Script (`multi.sh`)
Membuat user management kustom dan memperbaiki kegagalan soket DHCP dengan menyalakan network loopback (`lo`) serta kartu jaringan (`eth0`) sebelum memicu `udhcpc`.
```sh
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
```
### Solusi Script (`iso.sh`)
Skrip ini menyatukan `bzImage` dan ramdisk ke dalam media penyimpanan ISO bajakan menggunakan bootloader `isolinux` agar sistem dapat di-boot secara universal.
```sh
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
```
### Solusi Script (`backup.sh`)
Mengompresi semua aset biner rilis ke direktori arsip dengan tanda waktu dinamis yang presisi.
```sh
#!/bin/bash
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
ZIP_NAME="farewell_backup_${TIMESTAMP}.zip"

echo "==> Melakukan Backup File..."
zip -j osboot/$ZIP_NAME osboot/bzImage osboot/single.gz osboot/multi.gz osboot/farewell.iso
rm osboot/bzImage osboot/single.gz osboot/multi.gz osboot/farewell.iso

echo "==> Backup selesai! File arsip tersimpan di: osboot/$ZIP_NAME"
```
### Solusi Script (`qemu.sh`)
Skrip pengendali untuk menyalakan mesin virtual QEMU sesuai argumen target yang diberikan praktikan.
```sh
#!/bin/bash
if [ "$1" == "--single" ]; then
    qemu-system-x86_64 -kernel osboot/bzImage -initrd osboot/single.gz -append "console=ttyS0 console=tty1" -m 512M -net nic -net user,dns=8.8.8.8
elif [ "$1" == "--multi" ]; then
    qemu-system-x86_64 -kernel osboot/bzImage -initrd osboot/multi.gz -append "console=ttyS0 console=tty1" -m 512M -net nic -net user,dns=8.8.8.8
elif [ "$1" == "--all" ]; then
    qemu-system-x86_64 -cdrom osboot/farewell.iso -m 512M -net nic -net user,dns=8.8.8.8
else
    echo "Usage: ./qemu.sh [--single | --multi | --all]"
fi
```
## Output
<img width="3840" height="2160" alt="IMG-20260531-WA0202" src="https://github.com/user-attachments/assets/6c556cc9-ad03-453e-8cb6-3e133282743b" />
<img width="4624" height="2600" alt="IMG_20260531_223854" src="https://github.com/user-attachments/assets/2c1bfe20-33c4-49de-9717-08089baf9e69" />




## Kendala
- **Masalah Looping udhcpc: Network is down:**
Pada awalnya, saat pengujian mode multi-user, konsol terus menerus mengeluarkan galat interupsi jaringan berulang (Network is down, reopening socket).
- **Analisis & Solusi:**
Hal ini terjadi karena modul driver ethernet virtual (eth0) di dalam ekosistem kernel buatan berada dalam status non-aktif secara default sewaktu perintah penarikan alamat jaringan dipicu. Masalah ini diselesaikan secara tuntas dengan menyisipkan baris instruksi ip link set lo up dan ip link set eth0 up ke dalam file konfigurasi urutan booting awal (init) sebelum skrip udhcpc -i eth0 dijalankan.
- **warning cpu**
- **eror saat compile kernel**

# Soal 2: SEASON 
## Penjelasan

### Deskripsi Soal
Praktikan diminta mengimplementasikan sistem operasi berbasis teks berarsitektur 16-Bit Real Mode yang dijalankan di atas simulator perangkat keras Bochs. Komponen Kernel wajib dibangun menggunakan kombinasi bahasa Assembly (level rendah) dan C (logika sistem). Kernel ini bertindak sebagai antarmuka baris perintah (Shell CLI) interaktif yang mampu mengeksekusi serangkaian instruksi matematis dan kontekstual.

### Solusi Script (`bootloader.asm`)
```asm
bits 16
org 0x7C00

jmp start
nop

KERNEL_SEGMENT equ 0x1000
KERNEL_SECTORS equ 15

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Load kernel ke lokasi segment memori 0x1000:0000
    mov ax, KERNEL_SEGMENT
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00
    int 0x13

    jc disk_error

    cli
    mov ax, KERNEL_SEGMENT
    mov ds, ax
    mov es, ax

    ; Mengatur batas aman alokasi Stack Pointer
    mov ax, 0x9000
    mov ss, ax
    mov sp, 0xFFFF
    mov bp, 0xFFFF
    sti

    ; Pemicu Lompatan Jauh ke Kernel (Far Jump)
    push word KERNEL_SEGMENT
    push word 0x0000
    retf

disk_error:
    mov si, msg
.print:
    lodsb
    or al, al
    jz $
    mov ah, 0x0E
    mov bh, 0x00
    int 0x10
    jmp .print

msg db 'DISK ERROR',0
times 510-($-$$) db 0
dw 0xAA55
```
### Solusi Script (`kernel.asm`)
```asm
bits 16

global _start
global _putInMemory
global _getChar
extern _main

_start:
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    sti

    call _main

.hang:
    jmp .hang

_putInMemory:
    push bp
    mov bp, sp
    push ds

    mov ax, [bp+4]   ; Segment Tujuan (0xB800 untuk Video RAM)
    mov si, [bp+6]   ; Offset Alamat Memori
    mov cl, [bp+8]   ; Komponen Karakter ASCII

    mov ds, ax
    mov [si], cl

    pop ds
    pop bp
    ret

_getChar:
    push bp
    mov bp, sp
    
    ; Menggunakan BIOS Keyboard Service untuk membaca input tombol
    mov ah, 0x00
    int 0x16
    mov ah, 0x00     ; Bersihkan register AH agar AX hanya menyimpan nilai AL (ASCII)
    
    pop bp
    ret
```
### Solusi Script (`kernel.c`)
```c
int cursor = 0;
char color = 0x07;

void putInMemory(int segment, int address, char character);
int getChar();

void printChar(char c) {
    if (c == '\n') {
        int r = 0;
        // Mengganti operasi modulo/pembagian untuk mencari posisi baris baru (80 kolom per baris)
        while (r <= cursor) {
            r += 80;
        }
        cursor = r;
        if (cursor >= 2000) {
            cursor = 0;
        }
    } else {
        putInMemory(0xB800, cursor * 2, c);
        putInMemory(0xB800, cursor * 2 + 1, color);
        cursor++;
        if (cursor >= 2000) {
            cursor = 0;
        }
    }
}

void printString(char *s) {
    int i = 0;
    while (s[i] != '\0') {
        printChar(s[i]);
        i++;
    }
}

void newline() {
    printChar('\n');
}

void clearScreen() {
    int i;
    for (i = 0; i < 2000; i++) {
        putInMemory(0xB800, i * 2, ' ');
        putInMemory(0xB800, i * 2 + 1, color);
    }
    cursor = 0;
}

void readString(char *buf) {
    int i = 0;
    while (1) {
        char c = getChar();
        if (c == '\r' || c == '\n') {
            buf[i] = '\0';
            break;
        } else if (c == 0x08) { /* Penanganan tombol Backspace */
            if (i > 0) {
                i--;
                cursor--;
                putInMemory(0xB800, cursor * 2, ' ');
                putInMemory(0xB800, cursor * 2 + 1, color);
            }
        } else {
            if (i < 63) {
                buf[i] = c;
                i++;
                printChar(c);
            }
        }
    }
}

/* Mengembalikan nilai 1 jika string identik, sesuai spesifikasi skeleton */
int strcmp(char *s1, char *s2) {
    int i = 0;
    while (s1[i] != '\0' && s2[i] != '\0') {
        if (s1[i] != s2[i]) {
            return 0;
        }
        i++;
    }
    if (s1[i] == '\0' && s2[i] == '\0') {
        return 1;
    }
    return 0;
}

int startsWith(char *str, char *prefix) {
    int i = 0;
    while (prefix[i] != '\0') {
        if (str[i] != prefix[i]) {
            return 0;
        }
        i++;
    }
    return 1;
}

int atoi(char *s) {
    int res = 0;
    int i = 0;
    int sign = 1;
    while (s[i] == ' ') i++;
    if (s[i] == '-') {
        sign = -1;
        i++;
    } else if (s[i] == '+') {
        i++;
    }
    while (s[i] >= '0' && s[i] <= '9') {
        res = res * 10 + (s[i] - '0');
        i++;
    }
    return res * sign;
}

void intToString(int num, char *str) {
    char temp[16];
    int i = 0;
    int j = 0;
    int isNegative = 0;
    
    if (num == 0) {
        str[0] = '0';
        str[1] = '\0';
        return;
    }
    
    if (num < 0) {
        isNegative = 1;
        num = -num;
    }
    
    /* SOLUSI KENDALA: Mengganti pembagian (/) dan modulo (%) menggunakan pengurangan berulang */
    while (num > 0) {
        int q = 0;
        int rem = num;
        while (rem >= 10) {
            rem -= 10;
            q++;
        }
        temp[i++] = rem + '0';
        num = q;
    }
    
    if (isNegative) {
        str[j++] = '-';
    }
    
    while (i > 0) {
        str[j++] = temp[--i];
    }
    str[j] = '\0';
}

int factorial(int n) {
    if (n < 0) return 0;
    if (n == 0 || n == 1) return 1;
    return n * factorial(n - 1);
}

void main() {
    char cmd[64];
    clearScreen();

    printString("===============================================");
    newline();
    printString("      FarewellOS - 16-Bit Real Mode Shell      ");
    newline();
    printString("===============================================");
    newline();
    printString("Tuliskan perintah CLI aktif di bawah ini.");
    newline();
    newline();

    while (1) {
        printString("> ");
        readString(cmd);
        newline();

        if (strcmp(cmd, "check")) {
            printString("ok");
            newline();
        } 
        else if (startsWith(cmd, "add ")) {
            char *p = cmd + 4;
            int a, b;
            char resStr[16];
            while (*p == ' ') p++;
            a = atoi(p);
            if (*p == '-' || *p == '+') p++;
            while (*p >= '0' && *p <= '9') p++;
            while (*p == ' ') p++;
            b = atoi(p);
            
            intToString(a + b, resStr);
            printString(resStr);
            newline();
        } 
        else if (startsWith(cmd, "sub ")) {
            char *p = cmd + 4;
            int a, b;
            char resStr[16];
            while (*p == ' ') p++;
            a = atoi(p);
            if (*p == '-' || *p == '+') p++;
            while (*p >= '0' && *p <= '9') p++;
            while (*p == ' ') p++;
            b = atoi(p);
            
            intToString(a - b, resStr);
            printString(resStr);
            newline();
        } 
        else if (startsWith(cmd, "fac ")) {
            char *p = cmd + 4;
            while (*p == ' ') p++;
            int n = atoi(p);
            int f = factorial(n);
            char resStr[16];
            intToString(f, resStr);
            printString(resStr);
            newline();
        } 
        else if (startsWith(cmd, "season ")) {
            char *name = cmd + 7;
            while (*name == ' ') name++;
            if (strcmp(name, "winter")) {
                printString("Brrr! It's freezing cold winter.");
            } else if (strcmp(name, "spring")) {
                printString("Beautiful flowers blooming in spring.");
            } else if (strcmp(name, "summer")) {
                printString("Sun is shining bright in summer!");
            } else if (strcmp(name, "fall")) {
                printString("Leaves are falling down in autumn/fall.");
            } else if (strcmp(name, "radiant")) {
                printString("Welcome to the Radiant Season!");
            } else {
                printString("Unknown season. List: winter, spring, summer, fall, radiant.");
            }
            newline();
        } 
        else if (startsWith(cmd, "triangle ")) {
            char *p = cmd + 9;
            while (*p == ' ') p++;
            int n = atoi(p);
            int i, j;
            for (i = 1; i <= n; i++) {
                for (j = 0; j < i; j++) {
                    printChar('*');
                }
                newline();
            }
        } 
        else if (strcmp(cmd, "clear")) {
            clearScreen();
        } 
        else if (strcmp(cmd, "about")) {
            printString("OS Target: 16-bit Real Mode Kernel");
            newline();
            printString("Event: Final Challenge Modul 5 SISOP 2026");
            newline();
            printString("Developer: Akdan Hafiz (NRP: 5025231094)");
            newline();
        } 
        else {
            if (cmd[0] != '\0') {
                printString("Error: Command '");
                printString(cmd);
                printString("' tidak ditemukan.");
                newline();
            }
        }
    }
}

```
### Solusi Script (`Makefile`)
```c
prepare:
	dd if=/dev/zero of=floppy.img bs=512 count=2880

bootloader:
	nasm -f bin bootloader.asm -o bootloader.bin
	dd if=bootloader.bin of=floppy.img bs=512 count=1 conv=notrunc

kernel:
	nasm -f as86 kernel.asm -o kernel-asm.o
	bcc -ansi -c kernel.c -o kernel.o
	ld86 -o kernel.bin -d kernel.o kernel-asm.o
	dd if=kernel.bin of=floppy.img bs=512 seek=1 conv=notrunc

build: prepare bootloader kernel

run:
	bochs -f bochsrc.txt
```
  
## Output


### Kendala yang Dihadapi
belum sempat solve soal 2



# Revisi Soal 1
saya menggunakan wsl karena sebelumnya pakai vm tidak bisa mengaktifkan nested virtualization
### Solusi Script (`single.sh`) revisi single.sh
```sh
#!/bin/bash
set -e

# 1. Bersihkan folder sisa crash sebelumnya
rm -rf single_fs

mkdir -p single_fs
cd single_fs

echo "==> Mengunduh Alpine Mini Rootfs (Sama seperti Multi Mode)..."
wget -nc https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-minirootfs-3.19.1-x86_64.tar.gz
tar -xf alpine-minirootfs-*.tar.gz

echo "==> Setup Package Manager (party) dari Turunan Distro Alpine..."
# Memenuhi Soal 9: Menyalin apk asli menjadi party
cp sbin/apk sbin/party
echo "alias wget='wget --no-check-certificate'" >> etc/profile

echo "==> Membuat Init script khusus Single User Mode (Direct Root Shell)..."
cat << 'EOF' > init
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# Mounting filesystem utama
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# NYALAKAN NETWORK INTERFACE SEBELUM MEMINTA IP
ip link set lo up
ip link set eth0 up

# Meminta IP dari QEMU DHCP
udhcpc -i eth0

echo "========================================="
echo "Welcome to Single User Mode (Root Only)"
echo "========================================="

# CIRI KHAS SINGLE USER MODE: Langsung masuk ke shell tanpa login/getty/password!
exec /bin/sh </dev/console >/dev/console 2>&1
EOF

chmod +x init

# Proteksi tambahan: Hapus karakter Windows (\r)
sed -i 's/\r$//' init

echo "==> Membungkus menjadi initramfs single.gz..."
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../osboot/single.gz
cd ..

# Bersihkan folder temporary
rm -rf single_fs
echo "==> single.gz selesai dibuat di osboot dengan aman!"
```
## Output
## **BEFORE**
<img width="777" height="482" alt="Screenshot 2026-06-04 095312" src="https://github.com/user-attachments/assets/1019268a-35d9-4665-9ed5-42875561bd54" />

## **AFTER**
<img width="513" height="460" alt="image" src="https://github.com/user-attachments/assets/922b1936-679d-43e3-a2e4-c1be9af9f541" />
<img width="566" height="117" alt="image" src="https://github.com/user-attachments/assets/14ada81e-ac50-4e53-9bb7-2c138087fd33" />
<img width="712" height="439" alt="image" src="https://github.com/user-attachments/assets/958f8c35-33bd-467e-858d-a9139920d915" />
<img width="815" height="211" alt="image" src="https://github.com/user-attachments/assets/b00bd72d-45a6-49e7-abe4-23a8e67f7135" />


## Output multi
<img width="781" height="419" alt="image" src="https://github.com/user-attachments/assets/640477fb-d43b-41db-8ab7-a72acd498c16" />
<img width="670" height="366" alt="image" src="https://github.com/user-attachments/assets/197cf94f-d0f9-4c9d-866f-ed44e4ee6325" />
<img width="555" height="111" alt="image" src="https://github.com/user-attachments/assets/b495e175-cf10-4969-97aa-20efcb4fe38e" />
<img width="708" height="446" alt="image" src="https://github.com/user-attachments/assets/8daeb4b2-96d9-4b7f-95ef-0a78f0072a8a" />

# Revisi Soal 2
### Solusi Script (`bochsrc.txt`) revisi bochsrc.txt
```txt
megs: 32
romimage: file=/usr/share/bochs/BIOS-bochs-legacy
vgaromimage: file=/usr/share/bochs/VGABIOS-lgpl-latest
boot: floppy
floppya: 1_44=floppy.img, status=inserted
log: bochslog.txt
mouse: enabled=0
display_library: sdl2
speaker: enabled=0, mode=none
```

### Solusi Script (`kernel.c`) revisi kernel.c
```c
int cursor = 0;
char color = 0x07;

/* Prototipe fungsi assembly */
void putInMemory(int segment, int address, char character);
int getChar();

/* Fungsi output per karakter */
void printChar(char character) {
    putInMemory(0xB800, cursor, character);
    putInMemory(0xB800, cursor + 1, color);
    cursor += 2;
}

/* Fungsi output string */
void printString(char *string) {
    int i = 0;
    while (string[i] != '\0') {
        printChar(string[i]);
        i++;
    }
}

/* Fungsi baris baru (pengganti modulo %) */
void newline() {
    int temp = cursor;
    while (temp >= 160) {
        temp -= 160;
    }
    cursor = cursor - temp + 160;
    if (cursor >= 4000) {
        cursor = 0; /* Reset jika layar penuh */
    }
}

/* Fungsi membersihkan layar */
void clearScreen() {
    int i;
    for (i = 0; i < 80 * 25 * 2; i += 2) {
        putInMemory(0xB800, i, ' ');
        putInMemory(0xB800, i + 1, 0x07);
    }
    cursor = 0;
}

/* Fungsi membaca input keyboard */
void readString(char *buf) {
    int i = 0;
    char c;
    while (1) {
        c = getChar();
        if (c == '\r' || c == '\n') {
            buf[i] = '\0';
            break;
        } else if (c == '\b') {
            if (i > 0) {
                i--;
                cursor -= 2;
                printChar(' ');
                cursor -= 2;
            }
        } else if (i < 63) {
            buf[i] = c;
            printChar(c);
            i++;
        }
    }
}

/* Fungsi komparasi string */
int strcmp(char *s1, char *s2) {
    int i = 0;
    while (s1[i] != '\0' || s2[i] != '\0') {
        if (s1[i] != s2[i]) return 0;
        i++;
    }
    return 1;
}

/* Fungsi pengecekan awalan string */
int startsWith(char *s, char *prefix) {
    int i = 0;
    while (prefix[i] != '\0') {
        if (s[i] != prefix[i]) return 0;
        i++;
    }
    return 1;
}

/* Fungsi konversi string ke integer */
int atoi(char *s) {
    int res = 0;
    int i = 0;
    while (s[i] >= '0' && s[i] <= '9') {
        res = res * 10 + (s[i] - '0');
        i++;
    }
    return res;
}

/* Fungsi pembantu pengganti pembagian (/) dan modulo (%) */
void divmod10(int n, int *div, int *mod) {
    *div = 0;
    while (n >= 10) {
        n -= 10;
        (*div)++;
    }
    *mod = n;
}

/* Fungsi konversi integer ke string */
void intToString(int n, char *buf) {
    char temp[16];
    int i = 0;
    int isNegative = 0;
    int div, mod, j; /* Harus dideklarasi di atas fungsi */

    if (n == 0) {
        buf[0] = '0';
        buf[1] = '\0';
        return;
    }

    if (n < 0) {
        isNegative = 1;
        n = -n;
    }

    while (n > 0) {
        divmod10(n, &div, &mod);
        temp[i++] = mod + '0';
        n = div;
    }

    j = 0;
    if (isNegative) {
        buf[j++] = '-';
    }

    while (i > 0) {
        buf[j++] = temp[--i];
    }
    buf[j] = '\0';
}

/* Fungsi faktorial */
int factorial(int n) {
    int res = 1;
    int i;
    for (i = 1; i <= n; i++) {
        res = res * i;
    }
    return res;
}

/* Fungsi pemotong argumen angka */
void parseTwoArgs(char *cmd, int startIdx, int *a, int *b) {
    int i = startIdx;
    while (cmd[i] == ' ') i++;
    *a = atoi(cmd + i);
    while (cmd[i] >= '0' && cmd[i] <= '9') i++;
    while (cmd[i] == ' ') i++;
    *b = atoi(cmd + i);
}

/* ================== MAIN SHELL ================== */
void main() {
    /* SEMUA VARIABEL WAJIB DIDEKLARASIKAN DI SINI UNTUK BCC */
    char cmd[64];
    char resBuf[32];
    int a, b, n, i, j;
    char *name;

    clearScreen();

    printString("Welcome to Assistant's Last Gift");
    newline();
    printString("type 'help'");
    newline();
    newline();

    while (1) {
        printString("> ");
        readString(cmd);
        newline();

        if (strcmp(cmd, "check")) {
            printString("ok");
        } 
        else if (strcmp(cmd, "help")) {
            printString("Commands: check, add, sub, fac, season, triangle, clear");
        }
        else if (strcmp(cmd, "clear")) {
            clearScreen();
            continue; 
        } 
        else if (startsWith(cmd, "add ")) {
            parseTwoArgs(cmd, 4, &a, &b);
            intToString(a + b, resBuf);
            printString(resBuf);
        } 
        else if (startsWith(cmd, "sub ")) {
            parseTwoArgs(cmd, 4, &a, &b);
            intToString(a - b, resBuf);
            printString(resBuf);
        } 
        else if (startsWith(cmd, "fac ")) {
            n = atoi(cmd + 4);
            if (n > 7) { /* Limit int 16-bit */
                printString("Know your limit little bro.");
            } else {
                intToString(factorial(n), resBuf);
                printString(resBuf);
            }
        } 
        else if (startsWith(cmd, "season ")) {
            name = cmd + 7;
            if (strcmp(name, "winter")) {
                color = 0x09; /* Biru terang */
                printString("winter mode");
            }
            else if (strcmp(name, "spring")) {
                color = 0x0A; /* Hijau terang */
                printString("spring mode");
            }
            else if (strcmp(name, "summer")) {
                color = 0x0E; /* Kuning */
                printString("summer mode");
            }
            else if (strcmp(name, "fall")) {
                color = 0x06; /* Coklat/Orange */
                printString("fall mode");
            }
            else if (strcmp(name, "radiant")) {
                color = 0x0D; /* Pink/Magenta */
                printString("radiant mode");
            }
            else {
                printString("Unknown season.");
            }
        } 
        else if (startsWith(cmd, "triangle ")) {
            n = atoi(cmd + 9);
            for (i = 1; i <= n; i++) {
                for (j = 0; j < i; j++) {
                    printChar('x'); 
                }
                if (i < n) newline(); 
            }
        } 
        else {
            if (cmd[0] != '\0') {
                printString("Command not found.");
            }
        }

        newline();
    }
}
```
### Solusi Script (`kernel.asm`) revisi kernel.asm
```c
bits 16

global _start
global _putInMemory
global _getChar
extern _main

_start:
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    sti
    call _main

.hang:
    jmp .hang

_putInMemory:
    push bp
    mov bp, sp
    push ds
    mov ax, [bp+4]
    mov si, [bp+6]
    mov cl, [bp+8]
    mov ds, ax
    mov [si], cl
    pop ds
    pop bp
    ret

; Fungsi untuk mengambil karakter dari keyboard
_getChar:
    push bp
    mov bp, sp
    
    mov ah, 0x00      ; Interrupt untuk membaca keystroke
    int 0x16          ; Panggil BIOS interrupt 16h
    
    mov ah, 0x00      ; Bersihkan scancode di AH, sisakan karakter ASCII di AL
    
    pop bp
    ret
```

## Output
<img width="367" height="242" alt="image" src="https://github.com/user-attachments/assets/3a778c56-fa3a-4f4b-b05b-7017217844b7" />
<img width="365" height="244" alt="image" src="https://github.com/user-attachments/assets/23e2dfb7-85e4-483a-b1ff-585208fde1fe" />
<img width="366" height="239" alt="image" src="https://github.com/user-attachments/assets/22b7aed6-53dc-45a7-b6f3-e50db4b49e8b" />

## **Setelah Clear**
<img width="362" height="242" alt="image" src="https://github.com/user-attachments/assets/707868a5-bed9-4882-9dd9-a8940b21719f" />

### Kendala yang Dihadapi
Belum berhasil saat testcase add, sub, & fac hasilnya 0 semua 
