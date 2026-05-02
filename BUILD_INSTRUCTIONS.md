# PBRP Build Instructions for Motorola Boston

This repo is a device tree, not a complete Android source checkout. Build it inside a full PBRP source tree.

## Supported Product

- Product: `pbrp_boston`
- Lunch targets:
  - `pbrp_boston-eng`
  - `pbrp_boston-userdebug`

## Manual Build

```bash
mkdir -p ~/pbrp-build/source
cd ~/pbrp-build/source

repo init -u https://github.com/PitchBlackRecoveryProject/manifest_pb.git -b android-14.0 --depth=1
repo sync -c -j"$(nproc --all)" --no-clone-bundle --no-tags --optimized-fetch --prune

mkdir -p device/motorola
git clone https://github.com/crazyhair806/device_tree_boston.git device/motorola/boston

. build/envsetup.sh
lunch pbrp_boston-eng
mka vendorbootimage -j"$(nproc --all)"
```

Build output:

```text
out/target/product/boston/vendor_boot.img
```

## Scripted Build

From this repository:

```bash
bash build-pbrp.sh
```

Useful options:

```bash
bash build-pbrp.sh --branch android-14.0 --skip-deps
```

Windows users can launch the same workflow through WSL2:

```powershell
.\build-pbrp.ps1 -PBRPBranch android-14.0 -SkipDeps
```

## Repo Layout

- `BoardConfig.mk`: board and recovery configuration
- `device.mk`: device packages and A/B settings
- `pbrp_boston.mk`: product definition
- `recovery.fstab`: recovery mount table
- `recovery/root/`: recovery init files
- `prebuilt/`: prebuilt kernel, DTB, and DTBO

## Important Notes

- The local `vendor/pbrp/config/*.mk` files are compatibility stubs, not replacements for the real top-level PBRP vendor config in a full source tree.
- `ALLOW_MISSING_DEPENDENCIES := true` is enabled in `BoardConfig.mk` for minimal-manifest scenarios; it helps bootstrap but should not be treated as proof that the tree is complete for every manifest variation.
- The update path expects an A/B device layout.

## Verification

After a successful build:

```bash
ls -lh out/target/product/boston/vendor_boot.img
```

You can inspect the image header:

```bash
hexdump -C out/target/product/boston/vendor_boot.img | head -5
```

## Flashing

```bash
fastboot flash vendor_boot out/target/product/boston/vendor_boot.img
fastboot reboot recovery
```

If your device requires a different flashing flow, confirm the partition layout before flashing.
