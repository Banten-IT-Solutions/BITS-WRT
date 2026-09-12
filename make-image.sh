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
# BASE packages (shared: opkg 24.10 + apk 25.12)
# =====================================================================
PACKAGES_BASE=" -dnsmasq dnsmasq-full cgi-io libiwinfo libiwinfo-data libiwinfo-lua liblua \
luci-base luci-lib-base luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full \
cpusage ttyd dmesg kmod-tun luci-lib-ipkg \
zram-swap adb luci luci-ssl block-mount htop bash curl wget-ssl \
tar unzip unrar gzip jq luci-app-ttyd nano httping screen openssh-sftp-server \
liblucihttp liblucihttp-lua libubus-lua lua luci-app-firewall luci-app-package-manager \
ca-bundle ca-certificates luci-compat coreutils-sleep coreutils-whoami file \
luci-base luci-lib-base luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full \
luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp \
luci-theme-bootstrap rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci \
rpcd-mod-rrdns uhttpd uhttpd-mod-ubus coreutils coreutils-base64 coreutils-nohup coreutils-stty libc coreutils-stat \
ip-full libuci-lua microsocks resolveip ipset iptables iptables-legacy \
iptables-mod-iprange iptables-mod-socket iptables-mod-tproxy kmod-ipt-nat luci-lua-runtime zoneinfo-asia zoneinfo-core \
perl perlbase-base perlbase-bytes perlbase-class perlbase-config perlbase-cwd perlbase-dynaloader perlbase-errno perlbase-essential perlbase-fcntl perlbase-file \
perlbase-filehandle perlbase-i18n perlbase-integer perlbase-io perlbase-list perlbase-locale perlbase-params perlbase-posix \
perlbase-re perlbase-scalar perlbase-selectsaver perlbase-socket perlbase-symbol perlbase-tie perlbase-time perlbase-unicore perlbase-utf8 perlbase-xsloader"

# USB Ethernet & Phone Tether Driver (shared)
PACKAGES_BASE+=" kmod-usb-net-rtl8150 kmod-usb-net-rtl8152 kmod-usb-net-asix kmod-usb-net-asix-ax88179"
PACKAGES_BASE+=" kmod-mii kmod-usb-net kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-rndis \
kmod-usb-ohci kmod-usb-uhci kmod-usb2 kmod-usb-ehci kmod-nls-utf8 \
usbutils libusb-1.0-0 kmod-phy-broadcom kmod-phylib-broadcom kmod-tg3"

# =====================================================================
# STANDARD-only extras, split per package manager (maintenance point)
#   opkg (24.10): kiddin9 feed tersedia -> extra LuCI apps
#   apk  (25.12): kiddin9 opkg-only -> tidak ada
# =====================================================================
PACKAGES_STD_OPKG=" luci-app-diskman luci-app-disks-info luci-app-poweroff luci-app-log-viewer luci-app-ramfree"
PACKAGES_STD_APK=""

# =====================================================================
# COMMON trailer (NAS + theme + file manager), shared
# =====================================================================
PACKAGES_COMMON=" kmod-usb-storage kmod-usb-storage-uas ntfs-3g luci-theme-bits luci-app-tinyfm"

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
# Amlogic-specific packages (standard)
# =====================================================================
handle_profile_packages() {
    PACKAGES+=" ath9k-htc-firmware btrfs-progs hostapd hostapd-utils kmod-ath kmod-ath9k kmod-ath9k-common kmod-ath9k-htc kmod-cfg80211 kmod-crypto-acompress kmod-crypto-crc32c kmod-crypto-hash kmod-fs-btrfs kmod-mac80211 wireless-tools wpa-cli wpa-supplicant"
    EXCLUDED+=" -procd-ujail"
}

# =====================================================================
# Minimal profile: core + user apps (lean, version-agnostic)
# =====================================================================
set_minimal_packages() {
PACKAGES+=" -dnsmasq -procd-ujail dnsmasq-full \
luci luci-ssl luci-compat luci-lua-runtime \
rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns \
uhttpd uhttpd-mod-ubus cgi-io \
bash jq nano ttyd luci-app-ttyd \
luci-theme-bits luci-theme-bootstrap \
kmod-tun kmod-inet-diag \
kmod-nft-tproxy kmod-nft-socket kmod-dummy \
kmod-usb-net-cdc-ether kmod-usb-net-cdc-ncm kmod-usb-net-rndis \
kmod-usb-storage usbutils \
curl ip-full ca-certificates \
zoneinfo-asia zoneinfo-core"
}

# =====================================================================
# Main build function
#   $1 profile  $2 tunnel  $3 variant  $4 remote  $5 container  $6 addon  $7 use_apk
# =====================================================================
build_firmware() {
    local profile=$1
    local tunnel_option=$2
    local variant=$3
    local remote=$4
    local container=$5
    local addon=$6
    local use_apk=$7

    log "Starting build for profile: $profile (variant: ${variant:-standard}, apk: ${use_apk:-false})"

    # Package list per variant + package manager
    if [ "$variant" == "minimal" ]; then
        PACKAGES=""
        set_minimal_packages
    else
        PACKAGES="$PACKAGES_BASE $PACKAGES_COMMON"
        handle_profile_packages "$profile"
        if [ "$use_apk" == "true" ]; then
            PACKAGES+="$PACKAGES_STD_APK"
        else
            PACKAGES+="$PACKAGES_STD_OPKG"
        fi
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

build_firmware "$1" "$2" "$3" "$4" "$5" "$6" "$7"