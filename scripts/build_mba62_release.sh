#!/bin/bash

set -e

# Set non-interactive dpkg configuration flags
export DEBIAN_FRONTEND=noninteractive

# Fix grub installation failure
apt-get install -y grub

# Fix broadcom-sta-dkms installation failure
apt-get install -y broadcom-sta-dkms

# Other build commands go here