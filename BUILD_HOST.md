# antiMac Host Build

Use a real `x86_64` Debian or Ubuntu host. This repo cannot complete the full build inside Android/PRoot because `mount()` and `losetup` are unavailable there.

## Requirements

- `x86_64` Linux host
- passwordless `sudo`
- working loop devices
- working bind mounts and `chroot`

## One-command build

```bash
cd /path/to/antimac
chmod +x scripts/build_mba62_release.sh
./scripts/build_mba62_release.sh
```

The script will:

- fetch the real `antix-extracted/antiX/linuxfs` if the checkout only has the Git LFS pointer
- unsquash into `squashfs-root`
- apply the MacBook Air 6,2 customizations
- install the requested packages in chroot
- rebuild `antix-extracted/antiX/linuxfs`
- build `antimac-live.iso`
- build `antimac-installed.img`
- package `antimac-mba6.2-release.zip`

## Outputs

- `Build_Report.txt`
- `antimac-live.iso`
- `antimac-installed.img`
- `antimac-mba6.2-release.zip`
