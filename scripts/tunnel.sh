#!/bin/bash

. ./scripts/lib.sh

# OpenClash core (mihomo); nikki & momo resolve from feeds
OPENCLASH_CORE_DIR="files/etc/openclash/core"
OPENCLASH_CORE_FILE="${OPENCLASH_CORE_DIR}/clash_meta"

download_openclash_core() {
    # Idempotent: skip jika core sudah ada (dipanggil sekali per tunnel terpilih)
    if [[ -s "${OPENCLASH_CORE_FILE}" ]]; then
        log "INFO" "OpenClash core already present, skipping download."
        return 0
    fi

    local meta_file="mihomo-linux-${ARCH_1}"

    local openclash_core
    openclash_core=$(curl -s "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest" \
        | grep "browser_download_url" \
        | grep -oE "https.*${meta_file}-v[0-9]+\.[0-9]+\.[0-9]+\.gz" | head -n 1)

    log "INFO" "Downloading OpenClash core (mihomo)"
    mkdir -p "${OPENCLASH_CORE_DIR}"
    ariadl "${openclash_core}" "${OPENCLASH_CORE_DIR}/clash_meta.gz"
    gzip -d "${OPENCLASH_CORE_DIR}/clash_meta.gz" || error_msg "Error: Failed to extract OpenClash core."
}

main() {
    # Validasi nilai sudah dilakukan di workflow (TUNNEL_SELECTED);
    # di sini generik: hanya openclash butuh file extra, sisanya no-op.
    case "$1" in
        *openclash*)
            download_openclash_core
            ;;
        *)
            log "INFO" "Tunnel '$1': no extra files needed (packages resolve from feeds)."
            ;;
    esac

    log "SUCCESS" "Tunnel setup completed."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"