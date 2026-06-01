#!/bin/bash
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
ZIP_NAME="farewell_backup_${TIMESTAMP}.zip"

echo "==> Melakukan Backup File..."
zip -j osboot/$ZIP_NAME osboot/bzImage osboot/single.gz osboot/multi.gz osboot/farewell.iso
rm osboot/bzImage osboot/single.gz osboot/multi.gz osboot/farewell.iso

echo "==> Backup selesai! File arsip tersimpan di: osboot/$ZIP_NAME"
