# Quick Start

## Windows

Run the WSL2 launcher from this repository:

```powershell
.\build-pbrp.ps1
```

Optional flags:

```powershell
.\build-pbrp.ps1 -PBRPBranch android-14.0 -SkipDeps
```

## Linux or WSL2

Run the shell helper:

```bash
bash build-pbrp.sh
```

Optional flags:

```bash
bash build-pbrp.sh --branch android-14.0 --skip-deps
```

## Manual Build

If you already have a full PBRP source tree:

```bash
mkdir -p device/motorola
git clone https://github.com/crazyhair806/device_tree_boston.git device/motorola/boston

. build/envsetup.sh
lunch pbrp_boston-eng
mka vendorbootimage
```

## Output

```text
out/target/product/boston/vendor_boot.img
```

## Requirements

- WSL2 or Linux for actual Android builds
- Roughly 80-100 GB free disk space for a fresh source sync
- Enough RAM/CPU to sustain a full Android recovery build

## Next Reference

- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)
- [TROUBLESHOOT_WSL2.md](TROUBLESHOOT_WSL2.md)
