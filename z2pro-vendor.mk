# Copyright (C) 2016 The CyanogenMod Project

PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,vendor/zuk/z2pro/proprietary/app,system/app)
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,vendor/zuk/z2pro/proprietary/bin,system/bin)
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,vendor/zuk/z2pro/proprietary/etc,system/etc)
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,vendor/zuk/z2pro/proprietary/framework,system/framework)
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,vendor/zuk/z2pro/proprietary/lib,system/lib)
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,vendor/zuk/z2pro/proprietary/lib64,system/lib64)
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,vendor/zuk/z2pro/proprietary/priv-app,system/priv-app)
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,vendor/zuk/z2pro/proprietary/usr,system/usr)
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,vendor/zuk/z2pro/proprietary/vendor,system/vendor)

-include vendor/extra/devices.mk

$(call inherit-product, vendor/qcom/binaries/msm8996/graphics/graphics-vendor.mk)
