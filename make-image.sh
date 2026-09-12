#!/bin/bash

# Exit on error
set -e

# Script configuration
BUILD_LOG="build_$(date +%Y%m%d_%H%M%S).log"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$BUILD_LOG"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$BUILD_LOG"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$BUILD_LOG"
    exit 1
}

# Profile info
make info

# Main configuration name
PACKAGES=""
EXCLUDED=""

# =====================================================================
# BASE — minimal inti, dipakai SEMUA variant (opkg + apk)
#   cuma: LuCI inti, dnsmasq-full, tunnel kmod, USB tethering (HiLink/rndis)
# =====================================================================
PACKAGES_BASE=" -dnsmasq dnsmasq-full \
luci luci-ssl luci-compat luci-lua-runtime \
luci-app-firewall luci-app-package-manager \
rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns \
uhttpd uhttpd-mod-ubus cgi-io \
luci-theme-bits luci-theme-bootstrap \
bash jq nano curl wget-ssl ca-bundle ca-certificates ip-full \
ttyd luci-app-ttyd \
parted fdisk lsblk btrfs-progs kmod-fs-btrfs \
kmod-tun kmod-inet-diag \
kmod-nft-tproxy kmod-nft-socket kmod-dummy \
kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-rndis \
kmod-usb-storage usbutils usb-modeswitch \
zoneinfo-asia zoneinfo-core"

# =====================================================================
# STANDARD — extra rich packages (shared opkg + apk)
# =====================================================================
PACKAGES_STD=" libiwinfo libiwinfo-data libiwinfo-lua liblua liblucihttp liblucihttp-lua libubus-lua libuci-lua lua libc libusb-1.0-0 \
htop unzip unrar gzip screen httping openssh-sftp-server file \
cpusage zram-swap adb block-mount microsocks resolveip dmesg \
coreutils coreutils-base64 coreutils-nohup coreutils-stty coreutils-stat coreutils-sleep coreutils-whoami \
ipset iptables iptables-legacy iptables-mod-iprange iptables-mod-socket iptables-mod-tproxy kmod-ipt-nat \
perl perlbase-base perlbase-bytes perlbase-class perlbase-config perlbase-cwd perlbase-dynaloader perlbase-errno perlbase-essential perlbase-fcntl perlbase-file \
perlbase-filehandle perlbase-i18n perlbase-integer perlbase-io perlbase-list perlbase-locale perlbase-params perlbase-posix \
perlbase-re perlbase-scalar perlbase-selectsaver perlbase-socket perlbase-symbol perlbase-tie perlbase-time perlbase-unicore perlbase-utf8 perlbase-xsloader \
kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 kmod-usb-net-asix kmod-usb-net-asix-ax88179 \
kmod-mii kmod-usb-net kmod-usb-ohci kmod-usb-uhci kmod-usb2 kmod-usb-ehci kmod-nls-utf8 \
kmod-phy-broadcom kmod-phylib-broadcom kmod-tg3 \
kmod-usb-storage-uas ntfs-3g \
luci-app-tinyfm"

# =====================================================================
# STANDARD extras, split per package manager (maintenance point)
#   opkg (24.10) / apk (25.12) — kosong untuk sekarang
# =====================================================================
PACKAGES_STD_OPKG=""
PACKAGES_STD_APK=""

# =====================================================================
# MINIMAL — strip default bloat. Only applied to variant "minimal";
#   standard keeps everything (OpenWrt defaults + profile packages).
#   luci-proto-ipv6/ppp stay: hard deps of luci-light.
# =====================================================================
PACKAGES_EXCLUDE_MINIMAL=" -odhcp6c -odhcpd-ipv6only -kmod-nf-conntrack6 -kmod-nf-log6 -kmod-nf-reject6 \
-ppp -ppp-mod-pppoe -kmod-ppp -kmod-pppoe -kmod-pppox -kmod-slhc \
-mkf2fs -libf2fs6 -kmod-fs-vfat -kmod-nls-cp437 -kmod-nls-iso8859"

# =====================================================================
# Tunnel option (shared)
# =====================================================================
OPENCLASH+="coreutils-nohup bash dnsmasq-full curl ca-certificates ipset ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base luci-app-openclash"
NIKKI+="nikki luci-app-nikki"
MOMO+="momo luci-app-momo"

handle_tunnel_option() {
    case "$1" in
        "openclash")
            PACKAGES+=" $OPENCLASH"
            ;;
        "nikki")
            PACKAGES+=" $NIKKI"
            ;;
        "momo")
            PACKAGES+=" $MOMO"
            ;;
        "openclash-nikki")
            PACKAGES+=" $OPENCLASH $NIKKI"
            ;;
        "openclash-momo")
            PACKAGES+=" $OPENCLASH $MOMO"
            ;;
        "nikki-momo")
            PACKAGES+=" $NIKKI $MOMO"
            ;;
        "openclash-nikki-momo")
            PACKAGES+=" $OPENCLASH $NIKKI $MOMO"
            ;;
        "no-tunnel"|"")
            # No extra tunnel packages
            ;;
        *)
            warn "Unknown tunnel option: $1 (skipping)"
            ;;
    esac
}

# =====================================================================
# Remote Services (shared)
# =====================================================================
TAILSCALE+=" tailscale luci-app-tailscale"
CLOUDFLARE+=" cloudflared luci-app-cloudflared"

handle_remote() {
    case "$1" in
        tailscale)
            PACKAGES+=" $TAILSCALE"
            ;;
        cloudflare)
            PACKAGES+=" $CLOUDFLARE"
            ;;
        both)
            PACKAGES+=" $TAILSCALE $CLOUDFLARE"
            ;;
        *)
            ;; # no remote services
    esac
}

# =====================================================================
# Container runtime (shared)
# =====================================================================
DOCKER+=" dockerd docker luci-app-dockerman"
PODMAN+=" podman"

handle_container() {
    case "$1" in
        docker)
            PACKAGES+=" $DOCKER"
            ;;
        podman)
            PACKAGES+=" $PODMAN"
            ;;
        *)
            ;; # no container runtime
    esac
}

# =====================================================================
# BITS addons (shared)
# =====================================================================
BANDIX+=" bandix luci-app-bandix"
BOT+=" bitsnetworksbot luci-app-bitsnetworksbot"

handle_addon() {
    case "$1" in
        bandix)
            PACKAGES+=" $BANDIX"
            ;;
        bot)
            PACKAGES+=" $BOT"
            ;;
        both)
            PACKAGES+=" $BANDIX $BOT"
            ;;
        *)
            ;; # no BITS addons
    esac
}

# =====================================================================
# WiFi + crypto. Applied to BOTH variants via build option (default on).
#   - ath9k: Atheros USB dongle driver
#   - brcmfmac: Broadcom BCM43438 SDIO (internal wifi on p212/b860h)
# SoC (s905x etc) is picked later by ophub `remake -b`; profile stays generic.
# =====================================================================
handle_wifi_packages() {
    local use_apk=$1

    PACKAGES+=" ath9k-htc-firmware hostapd hostapd-utils iw kmod-ath kmod-ath9k kmod-ath9k-common kmod-ath9k-htc kmod-cfg80211 kmod-crypto-acompress kmod-crypto-crc32c kmod-crypto-hash kmod-mac80211 wireless-tools wpa-cli wpa-supplicant"
    PACKAGES+=" kmod-brcmfmac brcmfmac-nvram-43430-sdio"
    if [ "$use_apk" == "true" ]; then
        PACKAGES+=" brcmfmac-firmware-43430-sdio"
    else
        PACKAGES+=" brcmfmac-firmware-43430a0-sdio"
    fi
    EXCLUDED+=" -procd-ujail"
}

# =====================================================================
# Extra Modem (4G/LTE USB dongle / modem rakitan). Applied to both variants.
#   usb-modeswitch: switch dongle storage->modem; comgt/uqmi/umbim: dial/proto;
#   luci-proto-*: LuCI WAN protocol; kmod-*: NCM/QMI/MBIM/serial drivers.
# =====================================================================
handle_modem_packages() {
    PACKAGES+=" comgt comgt-ncm uqmi umbim luci-proto-3g luci-proto-ncm luci-proto-qmi kmod-usb-net-qmi-wwan kmod-usb-net-cdc-mbim kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan kmod-usb-acm"
}

# =====================================================================
# Main build function
#   $1 profile  $2 tunnel  $3 variant  $4 remote  $5 container  $6 addon  $7 use_apk  $8 enable_wifi  $9 enable_modem
# =====================================================================
build_firmware() {
    local profile=$1
    local tunnel_option=$2
    local variant=$3
    local remote=$4
    local container=$5
    local addon=$6
    local use_apk=$7
    local enable_wifi=$8
    local enable_modem=$9

    log "Starting build for profile: $profile (variant: ${variant:-standard}, apk: ${use_apk:-false}, wifi: ${enable_wifi:-false}, modem: ${enable_modem:-false})"

    # Package list per variant + package manager
    if [ "$variant" == "minimal" ]; then
        PACKAGES="$PACKAGES_BASE $PACKAGES_EXCLUDE_MINIMAL"
    else
        PACKAGES="$PACKAGES_BASE $PACKAGES_STD"
        if [ "$use_apk" == "true" ]; then
            PACKAGES+="$PACKAGES_STD_APK"
        else
            PACKAGES+="$PACKAGES_STD_OPKG"
        fi
    fi

    # WiFi applied to BOTH variants via build option (default on)
    if [ "$enable_wifi" == "true" ]; then
        handle_wifi_packages "$use_apk"
    fi

    # Extra modem support applied to BOTH variants (default off)
    if [ "$enable_modem" == "true" ]; then
        handle_modem_packages
    fi

    # attendedsysupgrade is a 25.x-only default; drop it for parity with 24.10
    if [ "$use_apk" == "true" ]; then
        EXCLUDED+=" -attendedsysupgrade-common -luci-app-attendedsysupgrade"
    fi

    # Tunnel / remote / container / addon apply to both variants
    handle_tunnel_option "$tunnel_option"
    handle_remote "$remote"
    handle_container "$container"
    handle_addon "$addon"

    # Custom Files
    FILES="files"

    log "Building image..."
    make image PROFILE="$profile" PACKAGES="$PACKAGES $EXCLUDED" FILES="$FILES" 2>&1 | tee -a "$BUILD_LOG"

    if [ "${PIPESTATUS[0]}" -eq 0 ]; then
        log "Build completed successfully!"
    else
        error "Build failed. Check $BUILD_LOG for details."
    fi
}

# Main script execution
if [ -z "$1" ]; then
    error "Profile not specified"
fi

build_firmware "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"