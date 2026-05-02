#!/bin/bash
# PBRP Boston Recovery Build Script for WSL2 or Linux

set -euo pipefail

echo "=========================================="
echo "PBRP Boston Recovery Build Script"
echo "=========================================="

# Variables
PBRP_BRANCH="${PBRP_BRANCH:-android-14.0}"
MANIFEST_URL="https://github.com/PitchBlackRecoveryProject/manifest_pb.git"
SKIP_DEPS=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --branch)
            if [[ $# -lt 2 ]]; then
                echo "--branch requires a value" >&2
                exit 1
            fi
            PBRP_BRANCH="$2"
            shift 2
            ;;
        --skip-deps)
            SKIP_DEPS=1
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 [--branch <branch>] [--skip-deps]" >&2
            exit 1
            ;;
    esac
done

# Use the script location as the workspace base so the Linux path stays correct in WSL.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR/pbrp-build"
SOURCE_DIR="$WORK_DIR/source"
DEVICE_TREE_URL="https://github.com/crazyhair806/device_tree_boston.git"

# Step 1: Install build dependencies
if [[ "$SKIP_DEPS" -eq 0 ]]; then
    echo "[1/6] Installing build dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        git-core gnupg flex bison build-essential zip curl zlib1g-dev \
        gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev \
        x11-utils libxml2 libxml2-utils xsltproc openjdk-17-jdk \
        libssl-dev libffi-dev python3 python3-pip python3-dev
else
    echo "[1/6] Skipping dependency installation..."
fi

# Step 2: Create work directory
echo "[2/6] Setting up workspace..."
mkdir -p "$SOURCE_DIR"
cd "$SOURCE_DIR"

# Step 3: Ensure the repo tool is available
if ! command -v repo >/dev/null 2>&1; then
    echo "[3/6] Installing repo tool..."
    sudo curl -sSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
    sudo chmod a+x /usr/local/bin/repo
fi

# Step 4: Initialize PBRP manifest
echo "[4/6] Initializing PBRP source tree (this may take a few minutes)..."
if [ ! -d ".repo" ]; then
    repo init -u "$MANIFEST_URL" -b "$PBRP_BRANCH" --depth=1
fi

# Step 4: Sync PBRP source
echo "[4/6] Syncing PBRP source code (this may take 10-30 minutes)..."
cd "$SOURCE_DIR"
repo sync -c -j"$(nproc --all)" --no-clone-bundle --no-tags --optimized-fetch --prune

# Step 5: Clone or update device tree
echo "[5/6] Setting up device tree..."
DEVICE_PATH="$SOURCE_DIR/device/motorola"
mkdir -p "$DEVICE_PATH"
if [ -d "$DEVICE_PATH/boston" ]; then
    cd "$DEVICE_PATH/boston" && git pull --ff-only
else
    git clone "$DEVICE_TREE_URL" "$DEVICE_PATH/boston"
fi

# Step 6: Build vendor_boot recovery image
echo "[6/6] Building PBRP vendor_boot recovery (this may take 20-60 minutes)..."
cd "$SOURCE_DIR"
source build/envsetup.sh
lunch pbrp_boston-eng
mka vendorbootimage -j"$(nproc --all)"

# Show result
if [ -f "out/target/product/boston/vendor_boot.img" ]; then
    echo ""
    echo "=========================================="
    echo "✅ BUILD SUCCESSFUL!"
    echo "=========================================="
    echo "Vendor boot image: out/target/product/boston/vendor_boot.img"
    echo "Size: $(du -h out/target/product/boston/vendor_boot.img | cut -f1)"
    echo ""
    echo "Next steps:"
    echo "1. Connect your device via USB"
    echo "2. Enable USB debugging in Developer Options"
    echo "3. Run: fastboot flash vendor_boot vendor_boot.img"
    echo "4. Boot into recovery: fastboot reboot recovery"
else
    echo "❌ BUILD FAILED - vendor_boot.img not found"
    exit 1
fi
