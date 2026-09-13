<div align="center">
  <h1>BITS WRT</h1>
  <p>
    <a href="https://bits.co.id">
      <img src="https://img.shields.io/badge/Banten%20IT%20Solutions-BITS%20WRT-00C853?style=for-the-badge&logo=openwrt&logoColor=white" alt="BITS WRT" />
    </a>
  </p>
  <p>
    Custom OpenWrt firmware (BITS-WRT) for Amlogic devices &mdash; built with ImageBuilder and packed with tunneling, remote access, and a modern BITS LuCI theme.
  </p>
  <br>
  <p>
    <img src="https://img.shields.io/badge/OpenWrt-00A1E9?style=flat&logo=openwrt&logoColor=white" alt="OpenWrt" />
    <img src="https://img.shields.io/badge/LuCI-3D5780?style=flat" alt="LuCI" />
    <img src="https://img.shields.io/badge/Shell-4EAA25?style=flat&logo=gnu-bash&logoColor=white" alt="Shell" />
    <img src="https://img.shields.io/badge/Amlogic-ED1C24?style=flat" alt="Amlogic" />
    <img src="https://img.shields.io/badge/ARM64-0091BD?style=flat" alt="ARM64" />
    <img src="https://img.shields.io/badge/GitHub%20Actions-2088FF?style=flat&logo=githubactions&logoColor=white" alt="GitHub Actions" />
  </p>
</div>

---

## ✨ Features

| Feature                    | Description                                                                                                          |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Tunneling**              | OpenClash (MetaCubeX Mihomo), Nikki (Mihomo), dan Momo (sing-box) — kombinasi bebas.                                 |
| **Remote Access**          | Tailscale (mesh VPN) dan Cloudflare (cloudflared tunnel).                                                            |
| **Container Runtime**      | Docker (Dockerman) atau Podman.                                                                                      |
| **Monitoring & BOT**       | Bandix (limit kecepatan) dan BITS Networks Bot (kontrol via Telegram).                                               |
| **Extra Modem**            | Dukungan modem 4G/LTE USB — `usb-modeswitch`, `comgt`/`uqmi`/`umbim`, protokol NCM/QMI/MBIM.                         |
| **WiFi**                   | Driver `ath9k` (Atheros USB) dan `brcmfmac` (BCM43438 SDIO) — opsional per build.                                    |
| **BITS Theme**             | Tema LuCI modern `luci-theme-bits` — aksen biru langit + cyan, mode gelap oranye, banner SSH + sysinfo.              |
| **File Manager**           | `luci-app-bitsfilemanager` untuk kelola file dari web UI.                                                            |
| **Terminal**               | `ttyd` web terminal + `luci-app-ttyd`.                                                                               |
| **Huawei HiLink**          | `luci-app-huawei-hilink` untuk modem Huawei HiLink.                                                                  |
| **Storage**                | `parted` + `btrfs-progs` + `zram-swap` + partisi root tumbuh otomatis.                                               |

## 🛠️ Tech Stack

| Layer        | Technology                                                              |
| ------------ | ------------------------------------------------------------------------ |
| **Base**     | OpenWrt 24.10 / 25.12 (ImageBuilder)                                     |
| **Repack**   | [ophub/amlogic-s9xxx-openwrt](https://github.com/ophub/amlogic-s9xxx-openwrt) `remake` |
| **Package Mgr** | `opkg` (24.10) / `apk` (25.12+)                                      |
| **Theme**    | `luci-theme-bits` (luci-static/bits)                                     |
| **CI/CD**    | GitHub Actions (`workflow_dispatch`)                                     |

---

## 📁 Project Structure

```text
BITS-WRT/
├── .github/
│   ├── workflows/
│   │   ├── build.yml             # build firmware (workflow_dispatch) + release .img.xz
│   │   └── cleanup.yml           # stale issue/PR + delete workflow runs
│   └── ISSUE_TEMPLATE/           # bug / feature / config / firmware
├── files/                        # custom FILES di-inject ke gambar
│   └── etc/
│       ├── config/               # system, network, dhcp, firewall, luci,
│       │                         # momo, nikki, openclash, ttyd, fstab, dropbear
│       ├── momo/profiles/        # BITS.json (profil sing-box momo)
│       ├── nikki/profiles/       # BITS.yaml (profil mihomo nikki)
│       ├── crontabs/root         # cron default
│       ├── sysctl.conf
│       ├── rc.local
│       └── uci-defaults/99-init-settings.sh   # first-boot setup (passwd, repo, tunnel)
├── scripts/
│   ├── packages.sh               # download paket eksternal
│   ├── patch.sh                  # patch tema & brand
│   ├── tunnel.sh                 # konfigurasi tunnel (openclash/nikki/momo)
│   ├── modsdcard.sh              # mod SD card (Amlogic)
│   ├── openwrt-tf                # partisi root tumbuh ke medium penuh
│   ├── lib.sh
│   └── boot/                     # u-boot.bin + aml_autoscript
├── make-image.sh                 # entrypoint build (base/standard/minimal + opsi)
└── CHANGELOG.md
```

---

## 🚀 Quick Start

### Download

Ambil firmware dari [Releases](https://github.com/Banten-IT-Solutions/BITS-WRT/releases) — file `.img.xz` (Amlogic).

### Flash (Amlogic)

1. Ekstrak `.img.xz` → `.img`.
2. Tulis ke SD card / USB dengan [balenaEtcher](https://www.balena.io/etcher/) atau `dd`.
3. Colok ke box, boot dari SD card / USB.

> Build dengan opsi `mod_sdcard` menambahkan `u-boot.bin` + `aml_autoscript` agar box boot langsung dari SD card.

### Default Access

| Item       | Value             |
| ---------- | ----------------- |
| **IP**     | `20.20.20.20`     |
| **User**   | `root`            |
| **Pass**   | `bitswrt`         |
| **Host**   | `BITS-WRT`        |

---

## 🏗️ Build

Build dilakukan via GitHub Actions (`workflow_dispatch`). Opsi build:

| Option              | Choices                                                                                      |
| ------------------- | -------------------------------------------------------------------------------------------- |
| **Device**          | HG680P, B860H                                                                                |
| **OpenWrt**         | 24.10, 25.12                                                                                 |
| **Kernel**          | 6.6, 6.12                                                                                    |
| **Variant**         | Minimal, Standard                                                                            |
| **VPN Client**      | OpenClash, Nikki, Momo (dan kombinasinya) / No Tunnel                                         |
| **Remote Access**   | Tailscale, Cloudflare, keduanya / No Remote                                                  |
| **Container**       | Docker, Podman / No Runtime                                                                  |
| **Monitoring**      | Bandix, BITS Bot, keduanya / No Monitoring                                                   |
| **WiFi / Modem**    | Yes / No                                                                                     |
| **Mod SD Card**     | Yes / No                                                                                     |

Output: `BITS-WRT_<versi>_<board>_k<kernel>_<fitur>_<variant>.img.xz` sebagai pre-release.

---

## 📄 Credits

- [friWrt-MyWrtBuilder](https://github.com/frizkyiman/friWrt-MyWrtBuilder) by frizkyiman
- [MyWrtBuilder](https://github.com/Revincx/MyWrtBuilder) by Revincx
- [ULO-Builder](https://github.com/armarchindo/ULO-Builder) by DBAI
- [ophub/amlogic-s9xxx-openwrt](https://github.com/ophub/amlogic-s9xxx-openwrt)

---

<div align="center">
  <strong>BITS WRT</strong> Developed with ❤️ by <a href="https://bits.co.id"><strong>Banten IT Solutions</strong></a>
</div>