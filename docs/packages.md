# Paket per Opsi Build

Penjelasan paket yang di-install berdasarkan opsi build (`make-image.sh` + `scripts/packages.sh`).

## Strategi

`make image` = `BASE + variant + opsi`. Rumus (`build_firmware()`):

```text
minimal  = BASE - EXCLUDE_MINIMAL + opsi
standard = BASE + STD + STD_OPKG/APK + opsi
```

## 1. BASE — selalu ada di semua build

| Kelompok | Paket |
|----------|-------|
| LuCI inti | `luci luci-ssl luci-compat luci-lua-runtime`, `luci-app-firewall luci-app-package-manager` |
| RPC/web | `rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns`, `uhttpd uhttpd-mod-ubus cgi-io` |
| Tema | `luci-theme-bits luci-theme-bootstrap` |
| Tools dasar | `bash jq nano curl wget-ssl ca-bundle ca-certificates ip-full` |
| Terminal/Mikrotil | `ttyd luci-app-ttyd luci-app-huawei-hilink` |
| Partisi/resize | `parted fdisk lsblk btrfs-progs kmod-fs-btrfs` |
| Tunnel kmod | `kmod-tun kmod-inet-diag kmod-nft-tproxy kmod-nft-socket kmod-dummy` |
| USB tether | `kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-rndis`, `kmod-usb-storage usbutils usb-modeswitch` |
| DNS | `dnsmasq-full` (ganti `-dnsmasq`) |
| Timezone | `zoneinfo-asia zoneinfo-core` |

## 2. Variant option

### Standard (`variant=standard`) — `PACKAGES_STD`

- Tools: `htop unzip unrar gzip screen httping openssh-sftp-server file`
- `cpusage zram-swap adb block-mount microsocks resolveip dmesg`
- `coreutils coreutils-base64 coreutils-nohup coreutils-stty coreutils-stat coreutils-sleep coreutils-whoami`
- Perl lengkap (`perl` + semua `perlbase-*`)
- Driver NIC USB: `kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 kmod-usb-net-asix kmod-usb-net-asix-ax88179`, `kmod-phy-broadcom kmod-phylib-broadcom kmod-tg3`
- Storage: `kmod-usb-storage-uas ntfs-3g`
- File manager: `luci-app-bitsfilemanager luci-app-engsel`

### Minimal (`variant=minimal`) — `PACKAGES_EXCLUDE_MINIMAL`

- IPv6: `odhcp6c odhcpd-ipv6only kmod-nf-conntrack6 kmod-nf-log6 kmod-nf-reject6`
- PPPoE: `ppp ppp-mod-pppoe kmod-ppp kmod-pppoe kmod-pppox kmod-slhc`
- `mkf2fs libf2fs6 kmod-fs-vfat kmod-nls-cp437 kmod-nls-iso8859-1`

> `PACKAGES_STD_OPKG` / `PACKAGES_STD_APK` saat ini kosong (titik perawatan).

## 3. Opsi tambahan (aditif, berlaku kedua variant)

| Option | Nilai | Paket |
|--------|-------|-------|
| **Tunnel** | `openclash` | `coreutils-nohup bash dnsmasq-full curl ca-certificates ipset iptables-nft ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base luci-app-openclash` + core `clash_meta` (mihomo, dari MetaCubeX via `tunnel.sh`) |
| | `nikki` | `nikki luci-app-nikki` |
| | `momo` | `momo luci-app-momo` |
| **Remote** | `tailscale` | `tailscale luci-app-tailscale` |
| | `cloudflare` | `cloudflared luci-app-cloudflared` |
| **Container** | `docker` | `dockerd docker luci-app-dockerman` |
| | `podman` | `podman` |
| **Monitoring** | `bandix` | `bandix luci-app-bandix` |
| | `bot` | `bitsnetworksbot luci-app-bitsnetworksbot` |
| **WiFi** | `yes` | `ath9k-htc-firmware hostapd hostapd-utils iw kmod-ath kmod-ath9k kmod-ath9k-common kmod-ath9k-htc kmod-cfg80211 kmod-crypto-* kmod-mac80211 wireless-tools wpa-cli wpa-supplicant` + `kmod-brcmfmac brcmfmac-nvram-43430-sdio` + firmware BCM43438 (nama beda apk vs opkg) + buang `-procd-ujail` |
| **Extra Modem** | `yes` | `comgt comgt-ncm uqmi umbim luci-proto-3g luci-proto-ncm luci-proto-qmi kmod-usb-net-qmi-wwan kmod-usb-net-cdc-mbim kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan kmod-usb-acm` |

## 4. Otomatis (bukan opsi user)

- **apk (25.12)** → buang `-attendedsysupgrade-common -luci-app-attendedsysupgrade` (parity 24.10).
- **OpenClash core** → `clash_meta` (mihomo) didownload `scripts/tunnel.sh` dari `MetaCubeX/mihomo` release terbaru.

## 5. Sumber paket

| Sumber | Paket |
|--------|-------|
| Feed resmi OpenWrt | mayoritas BASE/STD |
| Feed `bits` (BITS-WRT-Packages) | `luci-theme-bits luci-app-bitsfilemanager bitsnetworksbot luci-app-bitsnetworksbot` |
| Feed `momo` | `momo luci-app-momo` |
| Feed `nikki` | `nikki luci-app-nikki` |
| GitHub release (`scripts/packages.sh`) | `bandix luci-app-bandix luci-app-openclash luci-app-huawei-hilink luci-app-engsel` |