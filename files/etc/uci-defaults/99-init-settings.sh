#!/bin/sh

exec > /root/setup.log 2>&1

msg() { echo "$*"; }

# dont remove!
# dont remove!
msg "Installed Time: $(date '+%A, %d %B %Y %T')"
msg "###############################################"
msg "Processor: $(ubus call system board | grep '\"system\"' | sed 's/ \+/ /g' | awk -F'\"' '{print $4}')"
msg "Device Model: $(ubus call system board | grep '\"model\"' | sed 's/ \+/ /g' | awk -F'\"' '{print $4}')"
msg "Device Board: $(ubus call system board | grep '\"board_name\"' | sed 's/ \+/ /g' | awk -F'\"' '{print $4}')"

if grep -q "OpenWrt" /etc/openwrt_release; then
  sed -i "s/\(DISTRIB_DESCRIPTION='OpenWrt [0-9]*\.[0-9]*\.[0-9]*\).*'/\1'/g" /etc/openwrt_release
  msg Branch version: "$(grep 'DISTRIB_DESCRIPTION=' /etc/openwrt_release | awk -F"'" '{print $2}')"
fi
echo "Tunnel Installed: $(opkg list-installed | grep -e luci-app-openclash -e luci-app-nikki -e luci-app-momo | awk '{print $1}' | tr '\n' ' ')"
echo "###############################################"

# Set login root password
(echo "bitswrt"; sleep 1; echo "bitswrt") | passwd > /dev/null

# hostname/timezone/NTP/network/dhcp/firewall shipped via files/etc/config/

# custom repo and Disable opkg signature check
echo "Setup custom repos"
sed -i 's/option check_signature/# option check_signature/g' /etc/opkg.conf
echo "src/gz bits https://banten-it-solutions.github.io/BITS-WRT-Packages" >> /etc/opkg/customfeeds.conf
echo "src/gz custom_pkg https://dl.openwrt.ai/latest/packages/$(grep "OPENWRT_ARCH" /etc/os-release | awk -F '"' '{print $2}')/kiddin9" >> /etc/opkg/customfeeds.conf

# default theme handled by luci-theme-bits (40_bits_theme)

echo "Setup misc settings"
# remove login password required when accessing terminal
uci set ttyd.@ttyd[0].command='/bin/bash --login'
uci commit

# configurating openclash (config ships directly as /etc/config/openclash via FILES)
if opkg list-installed | grep luci-app-openclash > /dev/null; then
  echo "Openclash Detected!"
  echo "Configuring Core..."
  chmod +x /etc/openclash/core/clash_meta
  ln -s /etc/openclash/core/clash_meta /etc/openclash/clash
  echo "setup complete!"
else
  echo "No Openclash Detected."
  rm -rf /etc/config/openclash
  rm -rf /etc/openclash
fi

# configurating Nikki
if opkg list-installed | grep luci-app-nikki > /dev/null; then
  echo "setup complete!"
else
  echo "No Nikki Detected."
  rm -rf /etc/config/nikki
  rm -rf /etc/nikki
fi

# configurating Momo
if opkg list-installed | grep luci-app-momo > /dev/null; then
  echo "setup complete!"
else
  echo "No Momo Detected."
  rm -rf /etc/config/momo
  rm -rf /etc/momo
fi

echo "All first boot setup complete!"
rm -f /etc/uci-defaults/$(basename $0)
exit 0