#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/bootdevice/by-name/recovery:62178550:0020ec1c533d531b8463813f602a10b7aa8eef5f; then
  applypatch -b /system/etc/recovery-resource.dat EMMC:/dev/block/bootdevice/by-name/boot:56100082:ff777f5cd0e7e25f89760207495ef3500e3dd61f EMMC:/dev/block/bootdevice/by-name/recovery 0020ec1c533d531b8463813f602a10b7aa8eef5f 62178550 ff777f5cd0e7e25f89760207495ef3500e3dd61f:/system/recovery-from-boot.p && log -t recovery "Installing new recovery image: succeeded" || log -t recovery "Installing new recovery image: failed"
else
  log -t recovery "Recovery image already installed"
fi
