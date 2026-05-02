#
# Copyright (C) 2026 The Project Byzantium Recovery Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product-if-exists, $(SRC_TARGET_DIR)/product/embedded.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# Inherit from boston device
$(call inherit-product, device/motorola/boston/device.mk)

# Inherit PBRP common configuration.
$(call inherit-product, vendor/pbrp/config/common.mk)
$(call inherit-product, vendor/pbrp/config/gsm.mk)

# Device identifier. This must come after all inclusions
PRODUCT_DEVICE := boston
PRODUCT_NAME := pbrp_boston
PRODUCT_BRAND := motorola
PRODUCT_MODEL := motorola
PRODUCT_MANUFACTURER := motorola
PRODUCT_RELEASE_NAME := Moto G Stylus 5G-2024
