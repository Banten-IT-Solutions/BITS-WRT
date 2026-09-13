# Changelog

Catatan perubahan signifikan untuk BITS-WRT builder.

## Unreleased

### Build System
- ImageBuilder `armsr/armv8` + repack [ophub/amlogic-s9xxx-openwrt](https://github.com/ophub/amlogic-s9xxx-openwrt).
- OpenWrt 24.10 (`opkg`) / 25.12 (`apk`).
- Board: Amlogic s905x — HG680P, B860H.

### Build Options
- **Tunnel** — OpenClash, Nikki (Mihomo), Momo (sing-box), kombinasi bebas.
- **Remote** — Tailscale, Cloudflare.
- **Container** — Docker (Dockerman), Podman.
- **Monitoring** — Bandix, BITS Networks Bot.
- **WiFi** — ath9k + brcmfmac BCM43438 SDIO.
- **Extra modem** — 4G/LTE USB (NCM/QMI/MBIM).
- **Variant** — minimal / standard.

### Packages & Feeds
- Custom feeds: `bits`, `momo`, `nikki`.
- `luci-theme-bits`, `luci-app-bitsfilemanager`, `luci-app-bitsxl`.

### Default (first boot)
- IP `20.20.20.20` · user `root` · pass `bitswrt` · hostname `BITS-WRT`.