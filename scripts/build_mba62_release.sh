#!/bin/bash
set -euo pipefail

# Run non-interactive installs in CI to avoid dpkg prompts
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_TERSE=1
export DEBIAN_PRIORITY=critical

# Use apt options to keep current config files and avoid interactive prompts
APT_OPTS='-y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'

# Update package lists
sudo apt-get update

# If broadcom-sta-dkms exists it can fail to build in the runner (missing kernel headers).
# Remove it to prevent dpkg/dkms failures in CI.
sudo apt-get remove --purge -y broadcom-sta-dkms || true

# Install grub packages non-interactively to avoid conffile prompts (grub-install prompts)
# We explicitly set APT options so dpkg will accept defaults.
sudo apt-get install $APT_OPTS grub-common grub2-common grub-pc-bin || true

# Ensure any broken installs are fixed without interaction
sudo apt-get -f install $APT_OPTS || true
sudo dpkg --configure -a || true

# Continue with the original build steps (preserve existing behavior)
# Other build commands go here
