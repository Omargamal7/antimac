TARGETS = mountkernfs.sh udev mountdevsubfs.sh keyboard-setup.sh cryptdisks cryptdisks-early networking mountall.sh mountall-bootclean.sh urandom checkroot.sh checkfs.sh alsa-utils mountnfs.sh mountnfs-bootclean.sh hwclock.sh brightness opensysusers ufw hostname.sh bootmisc.sh mount-configfs kmod stop-bootlogd-single procps x11-common checkroot-bootclean.sh bootlogd
INTERACTIVE = udev keyboard-setup.sh cryptdisks cryptdisks-early checkroot.sh checkfs.sh
udev: mountkernfs.sh
mountdevsubfs.sh: udev
keyboard-setup.sh: mountdevsubfs.sh
cryptdisks: udev checkroot.sh cryptdisks-early
cryptdisks-early: udev checkroot.sh
networking: mountkernfs.sh mountall.sh mountall-bootclean.sh urandom procps
mountall.sh: checkfs.sh checkroot-bootclean.sh
mountall-bootclean.sh: mountall.sh
urandom: mountall.sh mountall-bootclean.sh hwclock.sh
checkroot.sh: keyboard-setup.sh hostname.sh bootlogd
checkfs.sh: cryptdisks
alsa-utils: mountall.sh mountall-bootclean.sh mountnfs.sh mountnfs-bootclean.sh
mountnfs.sh: mountall.sh mountall-bootclean.sh networking
mountnfs-bootclean.sh: mountall.sh mountall-bootclean.sh mountnfs.sh
hwclock.sh: bootlogd
brightness: mountall.sh mountall-bootclean.sh
opensysusers: mountall.sh mountall-bootclean.sh
ufw: mountall.sh mountall-bootclean.sh
hostname.sh: bootlogd
bootmisc.sh: udev mountnfs.sh mountnfs-bootclean.sh mountall.sh mountall-bootclean.sh checkroot-bootclean.sh
mount-configfs: mountkernfs.sh kmod
kmod: checkroot.sh
stop-bootlogd-single: mountall.sh mountall-bootclean.sh
procps: udev mountall.sh mountall-bootclean.sh bootlogd
x11-common: mountnfs.sh mountnfs-bootclean.sh
checkroot-bootclean.sh: checkroot.sh
bootlogd: mountdevsubfs.sh
