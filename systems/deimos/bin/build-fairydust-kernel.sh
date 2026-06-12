#!/usr/bin/env bash
set -euo pipefail

# Builds AsahiLinux's fairydust kernel branch and sets it as the default boot
# entry. Follows: https://elsainmac.tistory.com/1017
#
# WARNING: this hard-resets ~/Projects/linux to origin/fairydust, since the
# fairydust branch is regularly rebased upstream. Any local commits or
# uncommitted changes in that tree will be lost.

LINUX_SRC="${LINUX_SRC:-$HOME/Projects/linux}"
BRANCH="${BRANCH:-fairydust}"
JOBS="${JOBS:-$(nproc)}"

cd "$LINUX_SRC"

git fetch origin "$BRANCH"
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"

running="$(uname -r)"
if [[ -f "/lib/modules/$running/config" ]]; then
  cp "/lib/modules/$running/config" .config
elif [[ -f "/boot/config-$running" ]]; then
  cp "/boot/config-$running" .config
else
  echo "No existing kernel config found to seed from (looked under /lib/modules/$running and /boot/config-$running)" >&2
  exit 1
fi

scripts/kconfig/merge_config.sh -m .config arch/arm64/configs/asahi.config

scripts/config --disable DEBUG_INFO
scripts/config --disable CONFIG_DEBUG_INFO_BTF
scripts/config --disable CONFIG_EFI_ZBOOT

# Built-in for boot stability — asahi.config sets these to =m, override back to =y
scripts/config --enable NVME_APPLE
scripts/config --enable APPLE_SART
scripts/config --enable SPI_HID_APPLE_OF
scripts/config --enable SPI_HID_APPLE_CORE

scripts/config --enable RUST
scripts/config --enable DRM_ASAHI

# Broadcom HCI priority commands (30fcc498ff7c) deadlock the ordered HCI
# workqueue when BT audio starts, freezing all BT traffic (e.g. BLE mouse).
# Re-enable once the hci_cmd_sync call in hci_sched_acl_pkt is made async.
scripts/config --disable BT_BRCMEXT

scripts/config --module TYPEC_DP_ALTMODE
scripts/config --module TYPEC_NVIDIA_ALTMODE
scripts/config --module TYPEC_TBT_ALTMODE

make olddefconfig

make "-j$JOBS"

KREL="$(make -s kernelrelease)"
MODDIR="/usr/lib/modules/$KREL"

sudo make INSTALL_MOD_STRIP=1 modules_install
sudo make dtbs_install "INSTALL_DTBS_PATH=$MODDIR/dtb"
sudo make vdso_install "INSTALL_VDSO_PATH=$MODDIR/vdso"
sudo make install

sudo rm -rf /boot/dtb
sudo ln -s "$MODDIR/dtb" /boot/dtb
sudo cp "$LINUX_SRC/.config" "/boot/config-$KREL"

sudo grubby --set-default "/boot/vmlinuz-$KREL"

echo "Built and set as default: $KREL"
