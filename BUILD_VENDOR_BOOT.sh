#!/bin/bash
################################################################################
# TWRP Vendor Boot Build Script for Motorola Moto G Stylus 2024 (boston)
# Build Environment: Android/TWRP Build System
# Branch: checkpoint-working
# Date: 2026-08-31
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

################################################################################
# STEP 1: Check Build Environment
################################################################################
log_info "Checking build environment..."

if [ -z "$ANDROID_BUILD_TOP" ]; then
    log_error "ANDROID_BUILD_TOP not set. Please source build/envsetup.sh first."
    exit 1
fi

if [ ! -f "$ANDROID_BUILD_TOP/build/envsetup.sh" ]; then
    log_error "Invalid TWRP build environment. Cannot find build/envsetup.sh"
    exit 1
fi

log_success "Build environment verified"
cd "$ANDROID_BUILD_TOP"

################################################################################
# STEP 2: Verify Prebuilt Files
################################################################################
log_info "Verifying prebuilt files..."

PREBUILT_KERNEL="device/motorola/boston/prebuilt/kernel"
PREBUILT_DTB="device/motorola/boston/prebuilt/dtb/boston.dtb"
PREBUILT_DTBO="device/motorola/boston/prebuilt/dtbo.img"

if [ ! -f "$PREBUILT_KERNEL" ]; then
    log_warning "Missing: $PREBUILT_KERNEL"
else
    KERNEL_SIZE=$(stat -f%z "$PREBUILT_KERNEL" 2>/dev/null || stat -c%s "$PREBUILT_KERNEL" 2>/dev/null)
    log_success "Found kernel: $PREBUILT_KERNEL ($(numfmt --to=iec-i --suffix=B $KERNEL_SIZE 2>/dev/null || echo $KERNEL_SIZE bytes))"
fi

if [ ! -f "$PREBUILT_DTB" ]; then
    log_warning "Missing: $PREBUILT_DTB"
else
    DTB_SIZE=$(stat -f%z "$PREBUILT_DTB" 2>/dev/null || stat -c%s "$PREBUILT_DTB" 2>/dev/null)
    log_success "Found DTB: $PREBUILT_DTB ($(numfmt --to=iec-i --suffix=B $DTB_SIZE 2>/dev/null || echo $DTB_SIZE bytes))"
fi

if [ ! -f "$PREBUILT_DTBO" ]; then
    log_warning "Missing: $PREBUILT_DTBO"
else
    DTBO_SIZE=$(stat -f%z "$PREBUILT_DTBO" 2>/dev/null || stat -c%s "$PREBUILT_DTBO" 2>/dev/null)
    log_success "Found DTBO: $PREBUILT_DTBO ($(numfmt --to=iec-i --suffix=B $DTBO_SIZE 2>/dev/null || echo $DTBO_SIZE bytes))"
fi

################################################################################
# STEP 3: Setup Build Configuration
################################################################################
log_info "Setting up build configuration..."

# Ensure we're on checkpoint-working branch
if git -C "device/motorola/boston" rev-parse --abbrev-ref HEAD | grep -q "checkpoint-working"; then
    log_success "On checkpoint-working branch"
else
    log_warning "Not on checkpoint-working branch. Current: $(git -C device/motorola/boston rev-parse --abbrev-ref HEAD)"
fi

################################################################################
# STEP 4: Lunch Device Configuration
################################################################################
log_info "Lunching device configuration..."

# Run lunch for twrp_boston variant
lunch twrp_boston-userdebug

################################################################################
# STEP 5: Build Vendor Boot
################################################################################
log_info "Building vendor_boot image..."
log_info "This may take several minutes..."

make vendor_boot -j$(nproc)

if [ $? -eq 0 ]; then
    log_success "Vendor boot build completed successfully!"
else
    log_error "Vendor boot build failed!"
    exit 1
fi

################################################################################
# STEP 6: Build Recovery Image
################################################################################
read -p "Build recovery image as well? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Building recovery image..."
    make recoveryimage -j$(nproc)
    
    if [ $? -eq 0 ]; then
        log_success "Recovery image build completed successfully!"
    else
        log_error "Recovery image build failed!"
        exit 1
    fi
fi

################################################################################
# STEP 7: Display Build Artifacts
################################################################################
log_info "Locating build artifacts..."

if [ -n "$OUT" ] && [ -d "$OUT" ]; then
    log_success "Build output directory: $OUT"
    
    if [ -f "$OUT/vendor_boot.img" ]; then
        VENDOR_BOOT_SIZE=$(stat -f%z "$OUT/vendor_boot.img" 2>/dev/null || stat -c%s "$OUT/vendor_boot.img" 2>/dev/null)
        log_success "vendor_boot.img: $(numfmt --to=iec-i --suffix=B $VENDOR_BOOT_SIZE 2>/dev/null || echo $VENDOR_BOOT_SIZE bytes)"
    fi
    
    if [ -f "$OUT/recovery.img" ]; then
        RECOVERY_SIZE=$(stat -f%z "$OUT/recovery.img" 2>/dev/null || stat -c%s "$OUT/recovery.img" 2>/dev/null)
        log_success "recovery.img: $(numfmt --to=iec-i --suffix=B $RECOVERY_SIZE 2>/dev/null || echo $RECOVERY_SIZE bytes)"
    fi
else
    log_warning "Could not determine build output directory"
fi

################################################################################
# STEP 8: Summary
################################################################################
log_success "Build process completed!"
log_info "Next steps:"
log_info "1. Flash vendor_boot.img and recovery.img to your device"
log_info "2. Verify booting into TWRP recovery"
log_info "3. Check logs for any issues"

exit 0
