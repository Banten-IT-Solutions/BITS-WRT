#!/bin/bash

. ./scripts/lib.sh

# GitHub release packages (downloaded to packages/)
declare -a packages_github=(
    "bandix_.*aarch64_generic|https://api.github.com/repos/timsaya/openwrt-bandix/releases/latest"
    "luci-app-bandix|https://api.github.com/repos/timsaya/luci-app-bandix/releases/latest"
)

# Verify downloaded packages exist
verify_packages() {
    local pkg_dir="packages"
    local -a failed_packages=()
    local -a package_list=("${!1}")

    if [[ ! -d "$pkg_dir" ]]; then
        log "ERROR" "Package directory not found: $pkg_dir"
        return 1
    fi

    local total_found
    total_found=$(find "$pkg_dir" \( -name "*.ipk" -o -name "*.apk" \) | wc -l)
    log "INFO" "Found $total_found package files"

    local package_files
    package_files=$(find "$pkg_dir" \( -name "*.ipk" -o -name "*.apk" \))

    for package in "${package_list[@]}"; do
        local pkg_name="${package%%|*}"
        if ! grep -qEi "$pkg_name" <<< "$package_files"; then
            failed_packages+=("$pkg_name")
        fi
    done

    local failed=${#failed_packages[@]}
    if ((failed > 0)); then
        log "WARNING" "$failed packages failed to download:"
        printf '%s\n' "${failed_packages[@]}" | while read -r pkg; do
            log "WARNING" "  - $pkg"
        done
        return 1
    fi

    log "SUCCESS" "All packages downloaded successfully"
    return 0
}

main() {
    local rc=0
    log "INFO" "Downloading GitHub release packages..."
    download_packages "github" packages_github[@] || rc=1
    verify_packages packages_github[@] || rc=1

    if [ $rc -eq 0 ]; then
        log "SUCCESS" "Package download completed successfully"
    else
        log "ERROR" "Package download failed"
    fi
    return $rc
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"