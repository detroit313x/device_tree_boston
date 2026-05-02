# Minimal PBRP common configuration stub.
# This file is provided so the device tree can be included in a PBRP build
# when a full PBRP source tree is not available.
#
# Replace this stub with the full PBRP config from a proper vendor/pbrp tree.
# If you are using this device tree inside a larger PBRP source tree,
# copy this file to the top-level vendor/pbrp/config/common.mk.

PRODUCT_PACKAGES += \
    pbrp \
    libz \
    liblz4 \
    liblzma
