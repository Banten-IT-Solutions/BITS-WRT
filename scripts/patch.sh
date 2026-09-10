#!/bin/bash

. ./scripts/lib.sh

# Initialize environment
init_environment() {
    log "INFO" "Start Builder Patch!"
    log "INFO" "Current Path: $PWD"
    
    cd "$GITHUB_WORKSPACE/$WORKING_DIR" || error_msg "Failed to change directory"
}

# Patch package signature checking
patch_signature_check() {
    log "INFO" "Disabling package signature checking"
    sed -i '\|option check_signature| s|^|#|' repositories.conf
}

add_custom_feeds() {
    log "INFO" "Adding custom package feeds"
    cat >> repositories.conf <<EOF
src/gz bits https://banten-it-solutions.github.io/BITS-WRT-Packages
src/gz momo https://momomomo.pages.dev/openwrt-${VEROP}/${ARCH_3}/momo
src/gz nikki https://nikkinikki.pages.dev/openwrt-${VEROP}/${ARCH_3}/nikki
src/gz kiddin9 https://dl.openwrt.ai/releases/${VEROP}/packages/${ARCH_3}/kiddin9
EOF
}

# Patch Makefile for package installation
patch_makefile() {
    log "INFO" "Patching Makefile for force package installation"
    sed -i "s/install \$(BUILD_PACKAGES)/install \$(BUILD_PACKAGES) --force-overwrite --force-downgrade/" Makefile
}

# Apply Amlogic-specific configurations
configure_amlogic() {
    log "INFO" "Applying Amlogic-specific configurations"
    local configs=(
        "CONFIG_TARGET_ROOTFS_CPIOGZ"
        "CONFIG_TARGET_ROOTFS_EXT4FS"
        "CONFIG_TARGET_ROOTFS_SQUASHFS"
        "CONFIG_TARGET_IMAGES_GZIP"
    )
    
    for config in "${configs[@]}"; do
        sed -i "s|${config}=.*|# ${config} is not set|g" .config
    done
}

# Main execution
main() {
    init_environment
    patch_signature_check
    add_custom_feeds
    patch_makefile
    configure_amlogic
    log "INFO" "Builder patch completed successfully!"
}

# Execute main function
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
