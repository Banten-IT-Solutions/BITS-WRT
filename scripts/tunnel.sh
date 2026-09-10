#!/bin/bash

. ./scripts/lib.sh

# OpenClash core (mihomo); nikki & momo resolve from feeds
download_openclash_core() {
    local meta_file="mihomo-linux-${ARCH_1}"

    local openclash_core
    openclash_core=$(curl -s "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" \
        | grep "browser_download_url" \
        | grep -oE "https.*${meta_file}-v[0-9]+\.[0-9]+\.[0-9]+\.gz" | head -n 1)

    log "INFO" "Downloading OpenClash core (mihomo)"
    ariadl "${openclash_core}" "files/etc/openclash/core/clash_meta.gz"
    gzip -d "files/etc/openclash/core/clash_meta.gz" || error_msg "Error: Failed to extract OpenClash core."
}

main() {
    case "$1" in
        *openclash*)
            download_openclash_core
            ;;
    esac

    log "SUCCESS" "Tunnel setup completed."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"