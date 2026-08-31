# Motorola Boston PBRP Device Tree

This repository contains the Pitch Black Recovery Project (PBRP) device tree for Motorola Boston (`boston`, Moto G Stylus 5G 2024).

## What This Repo Contains

- Product definition for `pbrp_boston`
- Recovery fstab and init scripts
- Prebuilt kernel, DTB, and DTBO at `prebuilt/`
- WSL2/Linux build helpers

## Quick Start

Place this tree at `device/motorola/boston` inside a full PBRP source checkout, then build:

```bash
. build/envsetup.sh
lunch pbrp_boston-eng
mka vendorbootimage
```

Expected output:

```text
out/target/product/boston/vendor_boot.img
```

## Automated Build Helpers

- Linux/WSL2: `bash build-pbrp.sh`
- Windows launcher for WSL2: `.\build-pbrp.ps1`

Optional script arguments:

```bash
bash build-pbrp.sh --branch android-14.0 --skip-deps
```

```powershell
.\build-pbrp.ps1 -PBRPBranch android-14.0 -SkipDeps
```

## Notes

- This repo builds recovery into `vendor_boot.img`, not a standalone `recovery.img`.
- This repo is PBRP-focused. It no longer exports TWRP lunch targets.
- `vendor/pbrp/config/common.mk` and `vendor/pbrp/config/gsm.mk` are local compatibility stubs so the tree stays self-contained. In a real PBRP source tree, the top-level `vendor/pbrp/config` from that source should take precedence.
- The build scripts sync `https://github.com/PitchBlackRecoveryProject/manifest_pb.git` on branch `android-14.0` by default.

## More Docs

- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)
- [QUICK_BUILD.md](QUICK_BUILD.md)
- [TROUBLESHOOT_WSL2.md](TROUBLESHOOT_WSL2.md)
