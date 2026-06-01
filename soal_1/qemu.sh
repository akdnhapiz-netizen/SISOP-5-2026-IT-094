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
