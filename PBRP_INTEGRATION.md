# PBRP Integration Guide - Motorola Moto G Stylus 2024 (boston)

## 📋 Overview

This guide integrates the **PitchBlack Recovery Project (PBRP)** source with the Motorola boston device tree for building a complete TWRP/PBRP recovery.

**PBRP Status:** Project Byzantium Recovery (Official GitHub)
**Source:** https://github.com/PitchBlackRecoveryProject

---

## 🔗 Key PBRP Repositories

| Repository | Purpose | GitHub URL |
|------------|---------|-----------|
| **manifest_pb** | Build manifest (repo init) | https://github.com/PitchBlackRecoveryProject/manifest_pb |
| **android_bootable_recovery** | Core recovery code | https://github.com/PitchBlackRecoveryProject/android_bootable_recovery |
| **Documentation** | Build guides & setup | https://github.com/PitchBlackRecoveryProject/Documentation |

---

## 🚀 Quick Start - Set Up PBRP Build Environment

### Step 1: Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y bc bison build-essential curl flex g++ g++-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5 libncurses5-dev libreadline-dev libreadline6-dev libssl-dev libx11-dev libxml2 libxml2-utils lzop m4 make ncurses-dev openjdk-11-jdk openssl p7zip perl pkg-config python-is-python3 python3 python3-dev rsync schedtool squashfs-tools ssh sudo tar texinfo unzip w3m wget xsltproc zip zlib1g zlib1g-dev
```

### Step 2: Initialize PBRP Repo

```bash
mkdir -p ~/pbrp-workspace
cd ~/pbrp-workspace
repo init -u https://github.com/PitchBlackRecoveryProject/manifest_pb -b android-12.1
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

### Step 3: Sync PBRP Source

```bash
repo sync -j$(nproc)
```

---

## 🔧 Integrate boston Device Tree

### Step 1: Clone Device Tree

```bash
cd ~/pbrp-workspace
git clone https://github.com/detroit313x/device_tree_boston.git device/motorola/boston
cd device/motorola/boston
git checkout checkpoint-working
cd ~/pbrp-workspace
```

### Step 2: Create Recovery Root Files

```bash
mkdir -p device/motorola/boston/recovery/root
```

---

## 📝 Recovery Ramdisk Files

### 1. init.rc

**File:** `recovery/root/init.rc`

```ini
on early-init
    mount devtmpfs devtmpfs /dev mode=0755,nosuid,noexec
    mount proc proc /proc
    mount sysfs sysfs /sys
    mkdir /dev/pts 0755 root root
    mkdir /dev/socket 0755 root root
    mkdir /recovery 0000 root root
    mkdir /mnt 0755 root system
    mkdir /vendor_boot 0755 root root

on init
    write /sys/module/lowmemorykiller/parameters/minfree_0 18432
    write /sys/module/lowmemorykiller/parameters/minfree_1 36864
    write /sys/module/lowmemorykiller/parameters/minfree_2 55296
    load_all_props

on fs
    mount_all /fstab.qcom --early
    mount_all /fstab.qcom --late

on late-init
    trigger early-boot
    trigger boot

on boot
    class_start main
    setprop sys.boot_from_recovery 1
    setprop sys.usb.state adb
```

### 2. init.parrot.rc

**File:** `recovery/root/init.parrot.rc`

```ini
on fs
    mount_all /fstab.qcom --early

on boot
    class_start platform_service
```

### 3. init.boston.rc

**File:** `recovery/root/init.boston.rc`

```ini
on fs
    mkdir /metadata 0755 root root

on boot
    setprop ro.product.device boston
    setprop ro.product.model "Moto G Stylus 2024"
```

### 4. ueventd.rc

**File:** `recovery/root/ueventd.rc`

```ini
/dev/null                 0666   root       root
/dev/zero                 0666   root       root
/dev/random               0666   root       root
/dev/urandom              0666   root       root
/dev/block/mmcblk0        0660   root       disk
/dev/block/mmcblk0p*      0660   root       disk
/dev/block/bootdevice/*   0660   root       disk
/dev/ttyHS0               0660   root       system
```

### 5. default.prop

**File:** `recovery/root/default.prop`

```properties
ro.secure=1
ro.debuggable=0
ro.product.brand=motorola
ro.product.manufacturer=motorola
ro.product.model=Moto G Stylus 2024
ro.product.device=boston
ro.product.board=boston
ro.product.cpu.abi=arm64-v8a
ro.hardware=qcom
```

### 6. file_contexts

**File:** `recovery/root/file_contexts`

```
/dev(/.*)?                                   u:object_r:device:s0
/dev/block(/.*)?                             u:object_r:block_device:s0
/sys(/.*)?                                   u:object_r:sysfs:s0
/proc(/.*)?                                  u:object_r:proc:s0
/system(/.*)?                                u:object_r:system_file:s0
/vendor(/.*)?                                u:object_r:vendor_file:s0
/data(/.*)?                                  u:object_r:userdata_partition:s0
/metadata(/.*)?                              u:object_r:metadata_partition:s0
```

---

## 📦 Device Tree Binary (DTB)

Create DTB directory:
```bash
mkdir -p device/motorola/boston/prebuilt/dtb
```

If you have a prebuilt DTB, copy it:
```bash
cp /path/to/boston.dtb device/motorola/boston/prebuilt/dtb/boston.dtb
```

---

## ⚙️ Build Vendor Boot

### Step 1: Setup Build Environment

```bash
cd ~/pbrp-workspace
source build/envsetup.sh
```

### Step 2: Lunch Device

```bash
lunch pbrp_boston-userdebug
```

### Step 3: Build Vendor Boot Image

```bash
mka vendorbootimage -j$(nproc)
```

### Step 4: Verify Output

```bash
ls -lh $OUT/vendor_boot.img
file $OUT/vendor_boot.img
```

**Expected Output:**
```
-rw-r--r-- 1 user user 85M Aug 31 12:00 out/target/product/boston/vendor_boot.img
out/target/product/boston/vendor_boot.img: Android bootimg, kernel size 0, ramdisk size 0
```

---

## ✅ Build Completion Checklist

- [ ] PBRP source synced successfully
- [ ] Device tree integrated into device/motorola/boston/
- [ ] Recovery root files created
- [ ] DTB directory created
- [ ] `source build/envsetup.sh` completed without errors
- [ ] `lunch pbrp_boston-userdebug` works
- [ ] `mka vendorbootimage` completed
- [ ] `$OUT/vendor_boot.img` file exists
- [ ] Image file size is >50MB
- [ ] No build errors in output

---

## 📊 Vendor Boot Image Info

**File Location:** `out/target/product/boston/vendor_boot.img`

**Contents:**
- Kernel image
- Device tree (DTB)
- Ramdisk with recovery files
- Init scripts
- SELinux policy
- Device-specific configs

**Size:** Typically 80-120 MB

**Ready to Flash:**
```bash
fastboot flash vendor_boot $OUT/vendor_boot.img
fastboot reboot recovery
```

---

**Status:** Build Ready  
**Last Updated:** 2026-08-31  
**Device:** Motorola Moto G Stylus 2024 (boston)
