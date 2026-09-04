<div align="center">
  <h1>BITS-WRT</h1>
  <p>
    <a href="https://bits.co.id">
      <img src="https://img.shields.io/badge/Banten%20IT%20Solutions-BITS--WRT-00C853?style=for-the-badge&logo=openwrt&logoColor=white" alt="BITS-WRT" />
    </a>
  </p>
  <p>
    Minimal OpenWrt firmware for Amlogic TV boxes — Tailscale &amp; Singbox baked-in.
  </p>
  <br>
  <p>
    <img src="https://img.shields.io/badge/Platform-Amlogic%20S9xx-FF6D00?style=flat&logo=arm&logoColor=white" alt="Amlogic S9xx" />
    <img src="https://img.shields.io/badge/Base-OpenWrt-00B5E2?style=flat&logo=openwrt&logoColor=white" alt="OpenWrt" />
    <img src="https://img.shields.io/badge/VPN-Tailscale%20%2B%20Singbox-242424?style=flat&logo=tailscale&logoColor=white" alt="Tailscale + Singbox" />
    <img src="https://img.shields.io/badge/license-GPL--2.0-blue.svg?style=flat" alt="GPL-2.0 License" />
  </p>
</div>

---

## ✨ Features

| Feature             | Description                                                                  |
| ------------------- | ---------------------------------------------------------------------------- |
| **Minimal by design** | No hotspot, no billing, no WiFi — just a clean router.                      |
| **Tailscale**       | `tailscale` + `luci-app-tailscale-community` baked-in.                       |
| **Singbox**         | `momo` + `luci-app-momo` baked-in for proxying.                              |
| **Custom theme**    | `luci-theme-bits` — Paper / Classic / Terminal look.                         |
| **Single partition** | One-tap eMMC install: `p1` boot + `p2` rootfs fills the rest of the disk.    |
| **Auto-latest**     | CI tracks the newest OpenWrt stable release automatically.                   |

## 🛠️ Tech Stack

| Layer          | Technology                                        |
| -------------- | ------------------------------------------------- |
| **Base**       | OpenWrt (ImageBuilder)                            |
| **Build**      | ophub/amlogic-s9xxx-openwrt, GitHub Actions       |
| **UI**         | LuCI (ucode templates) + custom `luci-theme-bits` |
| **Provisioning** | uci-defaults (hostname, LAN, root password)     |
| **Packaging**  | `remake` → `.img.xz` (single partition eMMC)      |

## 🚀 Quick Start

**Default access**

| Setting  | Value          |
| -------- | -------------- |
| IP       | `20.20.20.20`  |
| Hostname | `bits-wrt`     |
| User     | `root`         |
| Password | `bitswrt`      |

**Flash**

```bash
unxz bits-wrt-25.12.5-<board>-k<kernel>.img.xz
sudo dd if=bits-wrt-25.12.5-<board>-k<kernel>.img \
        of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

**Install to eMMC**

Boot from SD/USB, then **System → BITS Service → Install OpenWrt**.

## 🎯 Supported Boards

| Board   | SoC      | Asset suffix           |
| ------- | -------- | ---------------------- |
| B860H   | s905x    | `b860h`                |
| HG680-P | s905x    | `hg680p`               |

Releases: https://github.com/Banten-IT-Solutions/BITS-WRT/releases

---

© Banten IT Solutions · [bits.co.id](https://bits.co.id)