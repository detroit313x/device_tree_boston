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
WORK_DIR="${PBRP_WORK_DIR:-$HOME/pbrp-build}"
SOURCE_DIR="$WORK_DIR/source"
# Some WSL environments expose /etc/gitconfig read-only to unprivileged repo
# cache writes. Avoid system git config during repo bootstrap/sync.
export GIT_CONFIG_NOSYSTEM=1

# Step 1: Install build dependencies
if [[ "$SKIP_DEPS" -eq 0 ]]; then
    echo "[1/6] Installing build dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        bash bc bison build-essential ca-certificates curl flex \
        g++-multilib gcc-multilib git-core gnupg libc6-dev-i386 \
        libffi-dev libssl-dev libxml2 libxml2-utils openjdk-17-jdk \
        python3 python3-dev python3-pip rsync unzip x11-utils \
        xsltproc xz-utils zip zlib1g-dev
    if ! sudo apt-get install -y -qq lib32ncurses-dev; then
        sudo apt-get install -y -qq lib32ncurses5-dev
    fi
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

REPO_BIN_DIR="$WORK_DIR/bin"
mkdir -p "$REPO_BIN_DIR"
python3 - "$(command -v repo)" "$REPO_BIN_DIR/repo" <<'PY'
from pathlib import Path
import sys

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
text = src.read_text()
needle = "        os.rename(dst, dst_final)\n"
patch = """        os.rename(dst, dst_final)\n\n        git_config = os.path.join(dst_final, \"git_config.py\")\n        if os.path.exists(git_config):\n            with open(git_config, \"r\", encoding=\"utf-8\") as fp:\n                data = fp.read()\n            old = \"\"\"    def _SaveJson(self, cache):\n        try:\n            with open(self._json, \\\"w\\\") as fd:\n                json.dump(cache, fd, indent=2)\n        except (OSError, TypeError):\n            platform_utils.remove(self._json, missing_ok=True)\n\"\"\"\n            new = \"\"\"    def _SaveJson(self, cache):\n        try:\n            with open(self._json, \\\"w\\\") as fd:\n                json.dump(cache, fd, indent=2)\n        except (OSError, TypeError):\n            pass\n\"\"\"\n            if old in data and new not in data:\n                with open(git_config, \"w\", encoding=\"utf-8\") as fp:\n                    fp.write(data.replace(old, new))\n"""
if needle in text and patch not in text:
    text = text.replace(needle, patch)
dst.write_text(text)
dst.chmod(0o755)
PY
export PATH="$REPO_BIN_DIR:$PATH"

# Step 4: Initialize PBRP manifest
echo "[4/6] Initializing PBRP source tree (this may take a few minutes)..."
if [ ! -d ".repo" ]; then
    repo init -u "$MANIFEST_URL" -b "$PBRP_BRANCH" --depth=1
fi

REPO_GIT_CONFIG="$SOURCE_DIR/.repo/repo/git_config.py"
if [ -f "$REPO_GIT_CONFIG" ]; then
    python3 - "$REPO_GIT_CONFIG" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = """    def _SaveJson(self, cache):
        try:
            with open(self._json, "w") as fd:
                json.dump(cache, fd, indent=2)
        except (OSError, TypeError):
            platform_utils.remove(self._json, missing_ok=True)
"""
new = """    def _SaveJson(self, cache):
        try:
            with open(self._json, "w") as fd:
                json.dump(cache, fd, indent=2)
        except (OSError, TypeError):
            pass
"""
if old in text and new not in text:
    path.write_text(text.replace(old, new))
PY
fi

# Step 4: Sync PBRP source
echo "[4/6] Syncing PBRP source code (this may take 10-30 minutes)..."
cd "$SOURCE_DIR"
repo sync -c -j"$(nproc --all)" --no-clone-bundle --no-tags --optimized-fetch --prune

# Step 5: Copy the local device tree into the source checkout
echo "[5/6] Setting up device tree..."
DEVICE_PATH="$SOURCE_DIR/device/motorola"
mkdir -p "$DEVICE_PATH"
rm -rf "$DEVICE_PATH/boston"
mkdir -p "$DEVICE_PATH/boston"
rsync -a --delete \
    --exclude ".git" \
    --exclude "pbrp-build" \
    --exclude ".repo" \
    "$SCRIPT_DIR"/ "$DEVICE_PATH/boston"/

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
    echo "BUILD SUCCESSFUL!"
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
    echo "BUILD FAILED - vendor_boot.img not found"
    exit 1
fi
