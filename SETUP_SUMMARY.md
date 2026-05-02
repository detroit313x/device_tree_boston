# PBRP Build Setup Summary

## Current State

This repository is set up as a PBRP-only device tree for Motorola Boston.

Included:

- `AndroidProducts.mk` with `pbrp_boston`
- `vendorsetup.sh` lunch combos for PBRP
- `pbrp_boston.mk` product definition
- Recovery init scripts and fstab
- Prebuilt kernel image
- WSL2/Linux build scripts
- Dockerfile for containerized setup

Not included:

- A full PBRP source tree
- Real top-level `vendor/pbrp/config` from the main PBRP source
- Any TWRP product file or TWRP lunch target

## Build Entry Points

- Manual: source `build/envsetup.sh`, then `lunch pbrp_boston-eng`
- Scripted Linux/WSL2: `bash build-pbrp.sh`
- Scripted Windows launcher: `.\build-pbrp.ps1`
- Container setup: `docker build -t pbrp-boston-builder .`

## Expected Output

```text
out/target/product/boston/vendor_boot.img
```

## Practical Constraints

- First sync/build still requires substantial disk, CPU, and network time.
- The included kernel and board config may still need device-specific validation on hardware.
- Successful compilation is not the same as confirmed bootability.
