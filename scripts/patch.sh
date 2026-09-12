#!/bin/bash

. ./scripts/lib.sh

# Initialize environment
init_environment() {
    log "INFO" "Start Builder Patch!"
    log "INFO" "Current Path: $PWD"

    cd "$GITHUB_WORKSPACE/$WORKING_DIR" || error_msg "Failed to change directory"
}

# Patch package signature checking (opkg only)
patch_signature_check() {
    log "INFO" "Disabling package signature checking"
    sed -i '\|option check_signature| s|^|#|' repositories.conf
}

# Add custom package feeds (opkg)
add_custom_feeds_opkg() {
    log "INFO" "Adding custom opkg package feeds"
    cat >> repositories.conf <<EOF
src/gz bits https://banten-it-solutions.github.io/BITS-WRT-Packages
src/gz momo https://momomomo.pages.dev/openwrt-${VEROP}/${ARCH_3}/momo
src/gz nikki https://nikkinikki.pages.dev/openwrt-${VEROP}/${ARCH_3}/nikki
EOF
}

# Add custom package feeds (apk repo = full path to packages.adb)
add_custom_feeds_apk() {
    log "INFO" "Adding custom apk package feeds"
    cat >> repositories <<EOF
https://banten-it-solutions.github.io/BITS-WRT-Packages/packages.adb
https://momomomo.pages.dev/openwrt-${VEROP}/${ARCH_3}/momo/packages.adb
https://nikkinikki.pages.dev/openwrt-${VEROP}/${ARCH_3}/nikki/packages.adb
EOF
}

# Disable signature check (apk): unsigned custom feeds tolerated
disable_signature_check_apk() {
    log "INFO" "Disabling package signature check (apk)"
    sed -i 's/^CONFIG_SIGNATURE_CHECK=.*/# CONFIG_SIGNATURE_CHECK is not set/' .config
}

# Patch Makefile for force package installation (opkg only)
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

    if [ "${USE_APK:-false}" == "true" ]; then
        disable_signature_check_apk
        add_custom_feeds_apk
    else
        patch_signature_check
        add_custom_feeds_opkg
        patch_makefile
    fi

    configure_amlogic
    log "INFO" "Builder patch completed successfully!"
}

# Execute main function
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"