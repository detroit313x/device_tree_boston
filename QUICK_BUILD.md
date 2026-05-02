# Quick Build

## Linux or WSL2

```bash
bash build-pbrp.sh
```

Skip package installation if your environment is already prepared:

```bash
bash build-pbrp.sh --skip-deps
```

Select a different PBRP branch:

```bash
bash build-pbrp.sh --branch android-14.0
```

## Windows PowerShell

```powershell
.\build-pbrp.ps1
```

With options:

```powershell
.\build-pbrp.ps1 -PBRPBranch android-14.0 -SkipDeps
```

## Manual Build

```bash
. build/envsetup.sh
lunch pbrp_boston-eng
mka vendorbootimage
```

## Output

```text
out/target/product/boston/vendor_boot.img
```
