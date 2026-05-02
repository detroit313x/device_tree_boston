# WSL2 Connection Timeout Troubleshooting & Manual Build Guide

## Problem: HCS_E_CONNECTION_TIMEOUT

**Error:** `The operation timed out because a response was not received from the virtual machine or container.`

**Root Cause:** WSL2/Hyper-V VM is not starting properly. This can be due to:
- Hyper-V service not running
- Resource contention (memory/CPU)
- WSL2 kernel or VM corruption
- Windows/WSL2 update conflicts

---

## Quick Troubleshooting Steps

### Step 1: Check Hyper-V Status
```powershell
# In PowerShell (Admin):
Get-Service Hyper-V | Select-Object Status, Name
# Should return: Status = Running
```

### Step 2: Check WSL Status
```powershell
wsl --status
wsl --list --verbose
# Ubuntu should show VERSION 2
```

### Step 3: Reset WSL2
```powershell
# Option A: Reset all WSL2 (WARNING: deletes all distributions)
wsl --unregister Ubuntu
# Then reinstall Ubuntu from Microsoft Store or Windows Terminal

# Option B: Just restart the Ubuntu VM (less destructive)
wsl --terminate Ubuntu
# Then run: wsl -d Ubuntu whoami
```

### Step 4: Test WSL2 Directly
```bash
# Try this in WSL2 Terminal (Windows Terminal app)
wsl -d Ubuntu bash
# If this connects, WSL2 works but PowerShell integration has issues

# Try a simple command:
wsl -d Ubuntu -e bash -c "uname -a"
```

---

## Manual Build Process (No Script)

If WSL2 troubleshooting doesn't help, use this manual step-by-step approach in Windows Terminal or WSL2 directly:

### Prerequisites
1. **Open Windows Terminal** (not PowerShell in VS Code)
2. **Select Ubuntu distribution** from the dropdown
3. You should see bash prompt: `user@hostname:~$`

### Build Steps

```bash
# 1. Create work directory
mkdir -p ~/pbrp-build/source
cd ~/pbrp-build/source

# 2. Install build dependencies (one-time)
sudo apt-get update
sudo apt-get install -y \
    git-core gnupg flex bison build-essential zip curl zlib1g-dev \
    gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev \
    x11-utils libxml2 libxml2-utils xsltproc openjdk-17-jdk \
    libssl-dev libffi-dev python3 python3-pip

# 3. Install repo tool (if not already installed)
if ! command -v repo &> /dev/null; then
    sudo curl -sSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
    sudo chmod a+x /usr/local/bin/repo
fi

# 4. Initialize PBRP manifest (android-14.0 branch)
repo init -u https://github.com/PitchBlackRecoveryProject/manifest_pb.git -b android-14.0 --depth=1

# 5. Sync PBRP source (this will take 15-30 minutes depending on network)
repo sync -c -j$(nproc --all) --no-clone-bundle --no-tags --optimized-fetch --prune

# 6. Add device tree (clone into correct location)
mkdir -p device/motorola
cd device/motorola
git clone https://github.com/crazyhair806/device_tree_boston.git boston
cd ~/pbrp-build/source

# 7. Set up build environment
source build/envsetup.sh

# 8. Select PBRP Boston variant
lunch pbrp_boston-userdebug
# Output should show: ============================================
#                     PBRP Boston Recovery (userdebug)
#                     ============================================

# 9. Build vendor boot recovery image (this will take 20-40 minutes)
mka vendorbootimage -j$(nproc --all)

# 10. Check if build succeeded
if [ -f "out/target/product/boston/vendor_boot.img" ]; then
    echo "✅ SUCCESS! Vendor boot image built."
    ls -lh out/target/product/boston/vendor_boot.img
else
    echo "❌ Build failed - vendor_boot.img not found"
    exit 1
fi
```

---

## Validation & Output Files

After successful build:

```bash
# Location: ~/pbrp-build/source/out/target/product/boston/

vendor_boot.img        # Main recovery image
boot.img               # Boot image
system.img             # System image (for reference)
```

### Verify Image Validity

```bash
# Check file exists and has reasonable size
ls -lh out/target/product/boston/vendor_boot.img

# Verify vendor_boot.img header
hexdump -C out/target/product/boston/vendor_boot.img | head -5
# Should show: 564e4452 = "VNDR" in the vendor boot header

# If abootimg tool is available:
abootimg -i out/target/product/boston/vendor_boot.img
```

---

## Copy to Windows (if building in WSL2)

```bash
# From WSL2 bash:
cp out/target/product/boston/vendor_boot.img /mnt/c/Users/Craig\ Hoyt/Downloads/vendor_boot.img

# Then access from Windows:
# C:\Users\Craig Hoyt\Downloads\vendor_boot.img
```

---

## If Manual Build Also Fails

Check the build log for errors:

```bash
# Last 100 lines of build output
tail -100 ~/pbrp-build/source/out/error.log

# Or search for ERROR lines:
grep "ERROR:" ~/pbrp-build/source/out/error.log | tail -20
```

**Common errors and fixes:**

| Error | Fix |
|-------|-----|
| `ERROR: Missing dependencies` | Run: `mka vendorbootimage 2>&1 \| grep -i "cannot find"` to identify missing packages |
| `No rule to make target 'pbrp'` | Missing PBRP source tree. Re-run `repo sync` |
| `Kernel: prebuilt/kernel not found` | Device tree not in correct location. Check: `ls -l device/motorola/boston/prebuilt/` |
| `Java version error` | Install Java 17: `sudo apt-get install openjdk-17-jdk` |

---

## Fallback: Local Native Build (Windows Only)

If WSL2 remains broken and you have AOSP build environment natively on Windows (unlikely but possible):

```powershell
# In PowerShell:
cd C:\pbrp\source
.\build\envsetup.bat
lunch pbrp_boston-userdebug
mka vendorbootimage
```

---

## Next: Flash to Device

Once vendor_boot.img is built successfully:

```bash
# From Linux/WSL2:
fastboot flash vendor_boot vendor_boot.img
fastboot reboot recovery
```

---

## Still Stuck?

**Option 1: Check WSL2 System Health**
```powershell
# In PowerShell (Admin):
wsl --update
wsl --shutdown
# Try again
```

**Option 2: Fresh Ubuntu Installation**
```powershell
# WARNING: This deletes the Ubuntu VM and all data in it!
wsl --unregister Ubuntu
# Reinstall from Microsoft Store or: wsl --install -d Ubuntu
```

**Option 3: Use Docker Alternative**
If you have Docker Desktop, build inside a container:
```powershell
docker pull ubuntu:22.04
# Then run build commands inside container
```

---

Generated: 2026-04-20 during troubleshooting
