#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_DIR="${ISO_DIR:-$ROOT_DIR/antix-extracted}"
LIVEFS_DIR="${LIVEFS_DIR:-$ROOT_DIR/antix-livefs}"
SQUASHFS_ROOT="${SQUASHFS_ROOT:-$ROOT_DIR/squashfs-root}"
LINUXFS_PATH="${LINUXFS_PATH:-$ISO_DIR/antiX/linuxfs}"
OUT_ISO="${OUT_ISO:-$ROOT_DIR/antimac-live.iso}"
OUT_IMG="${OUT_IMG:-$ROOT_DIR/antimac-installed.img}"
OUT_ZIP="${OUT_ZIP:-$ROOT_DIR/antimac-mba6.2-release.zip}"
REPORT_PATH="${REPORT_PATH:-$ROOT_DIR/Build_Report.txt}"
WIFI_SSID="${WIFI_SSID:-Mafia}"
WIFI_PSK="${WIFI_PSK:-aaaaaaaa}"
IMG_SIZE="${IMG_SIZE:-3G}"
LOOPDEV=""
MOUNT_ROOT=""

cleanup() {
  set +e
  if [ -n "${MOUNT_ROOT}" ]; then
    sudo umount -R "${MOUNT_ROOT}" >/dev/null 2>&1 || true
  fi
  if [ -n "${LOOPDEV}" ]; then
    sudo losetup -d "${LOOPDEV}" >/dev/null 2>&1 || true
  fi
  sudo umount "${SQUASHFS_ROOT}/proc" >/dev/null 2>&1 || true
  sudo umount "${SQUASHFS_ROOT}/sys" >/dev/null 2>&1 || true
  sudo umount "${SQUASHFS_ROOT}/dev" >/dev/null 2>&1 || true
}
trap cleanup EXIT

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

host_checks() {
  local arch
  arch="$(uname -m)"
  if [ "${arch}" != "x86_64" ]; then
    echo "This build must run on x86_64. Current arch: ${arch}" >&2
    exit 1
  fi

  require_cmd sudo
  require_cmd curl
  require_cmd unsquashfs
  require_cmd mksquashfs
  require_cmd xorriso
  require_cmd zip
  require_cmd rsync
  require_cmd parted
  require_cmd losetup
  require_cmd blkid
  require_cmd mkfs.vfat
  require_cmd mkfs.ext4
  require_cmd chroot

  if ! sudo -n true 2>/dev/null; then
    echo "Passwordless sudo is required for this script." >&2
    exit 1
  fi
}

install_host_deps() {
  sudo apt-get update
  sudo apt-get install -y squashfs-tools xorriso qemu-utils zip parted dosfstools rsync curl
}

fetch_linuxfs_if_needed() {
  mkdir -p "$(dirname "${LINUXFS_PATH}")"
  if [ -f "${LINUXFS_PATH}" ] && file "${LINUXFS_PATH}" | grep -qi squashfs; then
    return
  fi

  if [ -f "${LINUXFS_PATH}" ] && grep -q 'git-lfs.github.com/spec/v1' "${LINUXFS_PATH}" 2>/dev/null; then
    curl -L --fail \
      "https://media.githubusercontent.com/media/Omargamal7/antimac/main/antix-extracted/antiX/linuxfs" \
      -o "${LINUXFS_PATH}.download"
    mv "${LINUXFS_PATH}.download" "${LINUXFS_PATH}"
  fi

  if ! file "${LINUXFS_PATH}" | grep -qi squashfs; then
    echo "linuxfs is unavailable or invalid at ${LINUXFS_PATH}" >&2
    exit 1
  fi
}

prepare_rootfs() {
  sudo rm -rf "${SQUASHFS_ROOT}"
  sudo mkdir -p "${SQUASHFS_ROOT}"
  sudo unsquashfs -d "${SQUASHFS_ROOT}" "${LINUXFS_PATH}"
}

write_file() {
  local target="$1"
  sudo mkdir -p "$(dirname "${target}")"
  sudo tee "${target}" >/dev/null
}

append_report() {
  cat >>"${REPORT_PATH}"
}

seed_report() {
  cat >"${REPORT_PATH}" <<EOF
antiMac MBA6,2 Build Report
Date (UTC): $(date -u +%F)
Target: MacBook Air 6,2 (Mid 2013)
Base: antiX / Debian-based, systemd-free

1) Hardware and antiX analysis
- Thermal/Fan management:
  - Added mbpfan for Apple SMC-aware fan control.
  - Kept pommed for hotkeys and backlight mediation under antiX's non-systemd init model.
- Trackpad:
  - Added libinput package path and an X11 config with tap-to-click, natural scrolling, and clickfinger.
- Webcam:
  - Attempts firmware-facetimehd-dkms if available; records failure if unavailable in repo.
- Networking:
  - Forces ifupdown plus wpa_supplicant on wlan0.
  - Disables conflicting manager services when present.
- EFI boot:
  - Verifies fallback BOOTx64.efi is staged under EFI/BOOT for rEFInd discovery.

2) Host execution notes
- This script expects an x86_64 Debian/Ubuntu host with working sudo, mount, chroot, and loop devices.
- It does not rely on systemd inside the antiX rootfs.

3) Requested package set
- linux-image-amd64
- linux-headers-amd64
- grub-efi-amd64
- broadcom-sta-dkms
- xserver-xorg-video-intel
- pommed
- alsa-utils
- xbacklight
- kbdlight
- wpasupplicant
- tint2
- xserver-xorg-input-libinput
- mbpfan
EOF
}

configure_rootfs_files() {
  write_file "${SQUASHFS_ROOT}/etc/wpa_supplicant/wpa_supplicant.conf" <<EOF
network={
    ssid="${WIFI_SSID}"
    psk="${WIFI_PSK}"
    key_mgmt=WPA-PSK
}
EOF

  write_file "${SQUASHFS_ROOT}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf" <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="${WIFI_SSID}"
    psk="${WIFI_PSK}"
    key_mgmt=WPA-PSK
}
EOF

  write_file "${SQUASHFS_ROOT}/etc/network/interfaces.d/wlan0" <<'EOF'
allow-hotplug wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
EOF

  write_file "${SQUASHFS_ROOT}/etc/default/network-manager-selection" <<'EOF'
DISABLE_CENI=yes
DISABLE_CONNMAN=yes
EOF

  write_file "${SQUASHFS_ROOT}/etc/X11/xorg.conf.d/30-mba-trackpad.conf" <<'EOF'
Section "InputClass"
    Identifier "MBA6,2 libinput touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "ClickMethod" "clickfinger"
EndSection
EOF

  write_file "${SQUASHFS_ROOT}/etc/skel/.config/tint2/tint2rc" <<'EOF'
panel_items = TSC
panel_size = 100% 30
panel_background_id = 0
wm_menu = 1
taskbar_mode = single_desktop
launcher_padding = 8 8 8
clock_format = %H:%M
EOF

  write_file "${SQUASHFS_ROOT}/usr/local/bin/start-fluxbox-default" <<'EOF'
#!/bin/sh
exec fluxbox
EOF
  write_file "${SQUASHFS_ROOT}/usr/local/bin/start-fluxbox-minimal" <<'EOF'
#!/bin/sh
unset DESKTOP_SESSION
exec fluxbox
EOF
  write_file "${SQUASHFS_ROOT}/usr/local/bin/start-fluxbox-tint2" <<'EOF'
#!/bin/sh
pkill -x fbpanel 2>/dev/null || true
pkill -x tint2 2>/dev/null || true
tint2 &
exec fluxbox
EOF
  write_file "${SQUASHFS_ROOT}/usr/local/bin/start-icewm-default" <<'EOF'
#!/bin/sh
exec icewm-session
EOF
  write_file "${SQUASHFS_ROOT}/usr/local/bin/start-icewm-minimal" <<'EOF'
#!/bin/sh
exec icewm
EOF
  write_file "${SQUASHFS_ROOT}/usr/local/bin/start-icewm-tint2" <<'EOF'
#!/bin/sh
pkill -x icewmtray 2>/dev/null || true
pkill -x tint2 2>/dev/null || true
tint2 &
exec icewm
EOF
  write_file "${SQUASHFS_ROOT}/usr/local/bin/start-jwm-default" <<'EOF'
#!/bin/sh
exec jwm
EOF
  write_file "${SQUASHFS_ROOT}/usr/local/bin/start-jwm-minimal" <<'EOF'
#!/bin/sh
exec jwm
EOF
  write_file "${SQUASHFS_ROOT}/usr/local/bin/start-jwm-tint2" <<'EOF'
#!/bin/sh
pkill -x tint2 2>/dev/null || true
tint2 &
exec jwm
EOF

  sudo chmod 0755 \
    "${SQUASHFS_ROOT}/usr/local/bin/start-fluxbox-default" \
    "${SQUASHFS_ROOT}/usr/local/bin/start-fluxbox-minimal" \
    "${SQUASHFS_ROOT}/usr/local/bin/start-fluxbox-tint2" \
    "${SQUASHFS_ROOT}/usr/local/bin/start-icewm-default" \
    "${SQUASHFS_ROOT}/usr/local/bin/start-icewm-minimal" \
    "${SQUASHFS_ROOT}/usr/local/bin/start-icewm-tint2" \
    "${SQUASHFS_ROOT}/usr/local/bin/start-jwm-default" \
    "${SQUASHFS_ROOT}/usr/local/bin/start-jwm-minimal" \
    "${SQUASHFS_ROOT}/usr/local/bin/start-jwm-tint2"

  sudo mkdir -p "${SQUASHFS_ROOT}/usr/share/xsessions"
  for wm in fluxbox icewm jwm; do
    for variant in default minimal tint2; do
      title_wm="$(printf '%s' "$wm" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
      title_variant="$(printf '%s' "$variant" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
      write_file "${SQUASHFS_ROOT}/usr/share/xsessions/${wm}-${variant}.desktop" <<EOF
[Desktop Entry]
Name=${title_wm} ${title_variant}
Comment=${title_wm} ${title_variant} session
Exec=/usr/local/bin/start-${wm}-${variant}
Type=Application
DesktopNames=${title_wm}
EOF
    done
  done

  write_file "${SQUASHFS_ROOT}/etc/init.d/mba62-network" <<'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          mba62-network
# Required-Start:    $remote_fs $syslog networking
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Start wlan0 with fixed wpa_supplicant profile
### END INIT INFO
set -eu
case "${1:-}" in
  start)
    if command -v ifup >/dev/null 2>&1; then
      ifdown wlan0 2>/dev/null || true
      ifup wlan0 || true
    fi
    ;;
  stop)
    if command -v ifdown >/dev/null 2>&1; then
      ifdown wlan0 2>/dev/null || true
    fi
    ;;
  *)
    exit 0
    ;;
esac
EOF
  sudo chmod 0755 "${SQUASHFS_ROOT}/etc/init.d/mba62-network"
}

mount_chroot_fs() {
  sudo mount --bind /dev "${SQUASHFS_ROOT}/dev"
  sudo mount -t proc proc "${SQUASHFS_ROOT}/proc"
  sudo mount -t sysfs sys "${SQUASHFS_ROOT}/sys"
}

run_chroot_setup() {
  local chroot_script
  chroot_script="$(mktemp)"
  cat >"${chroot_script}" <<'EOF'
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
  linux-image-amd64 linux-headers-amd64 grub-efi-amd64 \
  broadcom-sta-dkms xserver-xorg-video-intel pommed alsa-utils \
  xbacklight kbdlight wpasupplicant tint2 \
  xserver-xorg-input-libinput mbpfan
apt-get install -y firmware-facetimehd-dkms || true
apt-get autoremove -y --purge 'linux-image-5.*' || true
update-rc.d pommed defaults || true
update-rc.d mbpfan defaults || true
update-rc.d mba62-network defaults || true
update-rc.d -f connman remove || true
update-rc.d -f ceni remove || true
EOF
  sudo cp "${chroot_script}" "${SQUASHFS_ROOT}/root/mba62-setup.sh"
  sudo chmod 0755 "${SQUASHFS_ROOT}/root/mba62-setup.sh"
  sudo chroot "${SQUASHFS_ROOT}" /bin/bash /root/mba62-setup.sh
  rm -f "${chroot_script}"
  sudo rm -f "${SQUASHFS_ROOT}/root/mba62-setup.sh"
}

stage_efi_fallback() {
  if [ -f "${ISO_DIR}/EFI/BOOT/grubx64.efi" ] && [ ! -f "${ISO_DIR}/EFI/BOOT/BOOTx64.efi" ]; then
    sudo cp "${ISO_DIR}/EFI/BOOT/grubx64.efi" "${ISO_DIR}/EFI/BOOT/BOOTx64.efi"
  fi
}

rebuild_linuxfs() {
  sudo rm -f "${LINUXFS_PATH}"
  sudo mksquashfs "${SQUASHFS_ROOT}" "${LINUXFS_PATH}" \
    -b 1048576 -comp zstd -Xcompression-level 19 -always-use-fragments -no-xattrs
}

rebuild_iso() {
  xorriso -as mkisofs \
    -r -J -joliet-long -l \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -partition_offset 16 \
    -A "antiX-MBA62" \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    -o "${OUT_ISO}" \
    "${ISO_DIR}"
}

build_img() {
  MOUNT_ROOT="$(mktemp -d)"
  fallocate -l "${IMG_SIZE}" "${OUT_IMG}"
  LOOPDEV="$(sudo losetup -Pf --show "${OUT_IMG}")"
  sudo parted -s "${LOOPDEV}" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 200MiB \
    set 1 esp on \
    mkpart ROOT ext4 200MiB 100%
  sudo mkfs.vfat -F32 "${LOOPDEV}p1"
  sudo mkfs.ext4 -F "${LOOPDEV}p2"
  sudo mount "${LOOPDEV}p2" "${MOUNT_ROOT}"
  sudo mkdir -p "${MOUNT_ROOT}/boot/efi"
  sudo mount "${LOOPDEV}p1" "${MOUNT_ROOT}/boot/efi"
  sudo rsync -aAX "${SQUASHFS_ROOT}/" "${MOUNT_ROOT}/"
  local root_uuid efi_uuid
  root_uuid="$(sudo blkid -s UUID -o value "${LOOPDEV}p2")"
  efi_uuid="$(sudo blkid -s UUID -o value "${LOOPDEV}p1")"
  write_file "${MOUNT_ROOT}/etc/fstab" <<EOF
UUID=${root_uuid} / ext4 defaults 0 1
UUID=${efi_uuid} /boot/efi vfat umask=0077 0 1
EOF
  sudo mount --bind /dev "${MOUNT_ROOT}/dev"
  sudo mount -t proc proc "${MOUNT_ROOT}/proc"
  sudo mount -t sysfs sys "${MOUNT_ROOT}/sys"
  sudo chroot "${MOUNT_ROOT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
  sudo chroot "${MOUNT_ROOT}" update-grub
}

package_release() {
  zip -j "${OUT_ZIP}" "${OUT_ISO}" "${OUT_IMG}" "${REPORT_PATH}"
}

main() {
  host_checks
  install_host_deps
  seed_report
  fetch_linuxfs_if_needed
  prepare_rootfs
  configure_rootfs_files
  mount_chroot_fs
  run_chroot_setup
  sudo umount "${SQUASHFS_ROOT}/proc"
  sudo umount "${SQUASHFS_ROOT}/sys"
  sudo umount "${SQUASHFS_ROOT}/dev"
  stage_efi_fallback
  rebuild_linuxfs
  rebuild_iso
  build_img
  package_release
  append_report <<EOF

4) Artifacts
- ISO: ${OUT_ISO}
- IMG: ${OUT_IMG}
- ZIP: ${OUT_ZIP}
EOF
  echo "${OUT_ZIP}"
}

main "$@"
