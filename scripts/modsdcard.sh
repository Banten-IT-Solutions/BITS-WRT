#!/bin/bash

. ./scripts/lib.sh

build_mod_sdcard() {
    local image_path="$1"
    local dtb="$2"
    local suffix="$3"

    log "STEPS" "Modifying boot files for Amlogic s905x devices..."
    
    # Validate input parameters
    if [ -z "$suffix" ] || [ -z "$dtb" ] || [ -z "$image_path" ]; then
        log "ERROR" "Missing required parameters. Usage: build_mod_sdcard <image_path> <dtb> <image_suffix>"
        return 1
    fi

    # Validate and set paths
    if ! cd "$GITHUB_WORKSPACE/$WORKING_DIR/compiled_images"; then
        log "ERROR" "Failed to change directory to $GITHUB_WORKSPACE/$WORKING_DIR/compiled_images"
        return 1
    fi

    local file_to_process="$image_path"

    cleanup() {
        log "INFO" "Cleaning up temporary files..."
        sudo umount boot 2>/dev/null || true
        sudo losetup -D 2>/dev/null || true
    }

    trap cleanup EXIT

    if [ -z "$file_to_process" ] || [ ! -f "$file_to_process" ]; then
        log "ERROR" "Image file not found: ${file_to_process}"
        return 1
    fi

    # Bootloader files vendored in repo (no external download)
    local bootfiles_dir="${GITHUB_WORKSPACE}/${WORKING_DIR}/scripts/boot"
    if [ ! -f "${bootfiles_dir}/u-boot.bin" ] || [ ! -f "${bootfiles_dir}/aml_autoscript" ]; then
        log "ERROR" "Bootloader files not found in ${bootfiles_dir}"
        return 1
    fi

    # Create working directory
    mkdir -p "${suffix}/boot"
    
    # Copy required files
    log "INFO" "Preparing image for ${suffix}..."
    cp "$file_to_process" "${suffix}/"
    if ! sudo cp "${bootfiles_dir}/u-boot.bin" "${bootfiles_dir}/aml_autoscript" "${suffix}/"; then
        log "ERROR" "Failed to copy bootloader files"
        return 1
    fi

    # Process the image
    cd "${suffix}" || {
        log "ERROR" "Failed to change directory to ${suffix}"
        return 1
    }

    local file_name
    file_name=$(basename "${file_to_process%.gz}")

    # Decompress the OpenWRT image
    if ! sudo gunzip "${file_name}.gz"; then
        log "ERROR" "Failed to decompress image"
        return 1
    fi

    # Set up loop device
    local device
    log "INFO" "Setting up loop device..."
    for _ in {1..3}; do
        device=$(sudo losetup -fP --show "${file_name}" 2>/dev/null)
        [ -n "$device" ] && break
        sleep 1
    done

    if [ -z "$device" ]; then
        log "ERROR" "Failed to set up loop device"
        return 1
    fi

    # Mount the image
    log "INFO" "Mounting the image..."
    local attempts=0
    while [ $attempts -lt 3 ]; do
        if sudo mount "${device}p1" boot; then
            break
        fi
        attempts=$((attempts + 1))
        sleep 1
    done

    if [ $attempts -eq 3 ]; then
        log "ERROR" "Failed to mount image"
        return 1
    fi

    # Apply boot files (gist: revive-dead-emmc-bootloader, Phase 3A + 3B)
    log "INFO" "Installing boot files..."
    if [ -f boot/u-boot-p212.bin ]; then
        for variant in u-boot.ext u-boot.sd u-boot.usb; do
            sudo cp -f "boot/u-boot-p212.bin" "boot/${variant}"
        done
        log "INFO" "u-boot variants installed."
    else
        log "WARNING" "u-boot-p212.bin not found in image, skipping u-boot variants."
    fi
    sudo cp -f aml_autoscript boot/aml_autoscript
    log "INFO" "aml_autoscript installed."

    # Armbian-style images ship extlinux.conf.bak; activate it when .conf is missing
    if [ ! -f boot/extlinux/extlinux.conf ] && [ -f boot/extlinux/extlinux.conf.bak ]; then
        sudo mv boot/extlinux/extlinux.conf.bak boot/extlinux/extlinux.conf
        log "INFO" "Activated extlinux.conf from .bak."
    fi

    # Update configuration files (DTB per model, ophub-style: uEnv/extlinux/boot.ini)
    log "INFO" "Updating configuration files..."
    local uenv extlinux
    [ -f boot/uEnv.txt ] && uenv=$(sudo cat boot/uEnv.txt | grep APPEND | awk -F "root=" '{print $2}')
    [ -f boot/extlinux/extlinux.conf ] && extlinux=$(sudo cat boot/extlinux/extlinux.conf | grep append | awk -F "root=" '{print $2}')

    if [ -n "$extlinux" ] && [ -n "$uenv" ]; then
        sudo sed -i "s|$extlinux|$uenv|g" boot/extlinux/extlinux.conf
    fi
    for f in boot/uEnv.txt boot/extlinux/extlinux.conf; do
        [ -f "$f" ] || continue
        log "INFO" "Patching DTB in $f..."
        sudo sed -i "s|meson-[A-Za-z0-9_.-]*\.dtb|$dtb|g" "$f"
        sudo sed -i "s|\(fdtfile=[^ /\"']*/\)[^ /\"']*$|\1$dtb|g" "$f"
    done
    # boot.ini (if present): only the devtype line points to model DTB
    if [ -f boot/boot.ini ]; then
        if grep -q 'setenv devtype' boot/boot.ini; then
            sudo sed -i "s|.*setenv devtype.*|if test \"\${devtype}\" = \"\"; then setenv devtype \"/dtb/amlogic/$dtb\"; fi|g" boot/boot.ini
            log "INFO" "devtype set to $dtb in boot.ini."
        else
            log "WARNING" "No devtype line in boot.ini, skipping."
        fi
    fi

    sync
    if ! sudo umount boot; then
        log "ERROR" "Failed to unmount boot partition, aborting to avoid corrupt image"
        return 1
    fi

    # Write bootloader
    log "INFO" "Writing bootloader..."
    if ! sudo dd if=u-boot.bin of="${device}" bs=1 count=444 conv=fsync 2>/dev/null || \
       ! sudo dd if=u-boot.bin of="${device}" bs=512 skip=1 seek=1 conv=fsync 2>/dev/null; then
        log "ERROR" "Failed to write bootloader"
        return 1
    fi

    # Detach loop device and compress
    sudo losetup -d "${device}"
    if ! sudo gzip "${file_name}"; then
        log "ERROR" "Failed to compress image"
        return 1
    fi

    if [ -f "../${file_name}.gz" ]; then
        rm -rf "../${file_name}.gz"
    fi
    mv "${file_name}.gz" "../${file_name}.gz" || {
        log "ERROR" "Failed to rename image file"
        return 1
    }

    cd ..
    rm -rf "${suffix}"
    cleanup
    log "SUCCESS" "Successfully processed ${suffix}"
    return 0
}

process_builds() {
    local img_dir="$1"
    local tunnel_mode="$2"
    local builds=("${@:3}")
    local exit_code=0
    
    # Daftar tunnel dari workflow env (TUNNEL_LIST); fallback agar script tetap bisa jalan standalone
    local tunnel_types=()
    if [[ "$tunnel_mode" == "all" ]]; then
        read -ra tunnel_types <<< "${TUNNEL_LIST:-openclash nikki momo openclash-nikki openclash-momo nikki-momo openclash-nikki-momo no-tunnel}"
    else
        tunnel_types=("$tunnel_mode")
    fi

    # Tiap tunnel diproses tepat sekali (find dibatasi suffix tunnel agar tidak dobel)
    for tunnel in "${tunnel_types[@]}"; do
        for build in "${builds[@]}"; do
            IFS=: read -r device kernel dtb model <<< "$build"
            local image_file
            image_file=$(find "$img_dir" -name "*_${device}_${kernel}*_${tunnel}.img.gz")

            if [[ -n "$image_file" ]]; then
                if ! build_mod_sdcard "$image_file" "$dtb" "$model"; then
                    log "ERROR" "Failed to process build for $model ($device $kernel) with tunnel: $tunnel"
                    exit_code=1
                fi
            else
                log "WARNING" "No image file found for $model ($device $kernel) with tunnel: $tunnel"
            fi
        done
    done

    return $exit_code
}

main() {
    local exit_code=0
    local img_dir="$GITHUB_WORKSPACE/$WORKING_DIR/compiled_images"
    
    # Configuration array with format device:kernel:dtb:model
    local builds=(
        "s905x:k6.6:meson-gxl-s905x-p212.dtb:HG680P"
        "s905x:k6.12:meson-gxl-s905x-p212.dtb:HG680P"
        "s905x-b860h:k6.6:meson-gxl-s905x-b860h.dtb:B860H_v1-v2"
        "s905x-b860h:k6.12:meson-gxl-s905x-b860h.dtb:B860H_v1-v2"
    )
    
    # Validate environment
    if [[ ! -d "$img_dir" ]]; then
        log "ERROR" "Image directory not found: $img_dir"
        return 1
    fi
    
    # Process builds
    if ! process_builds "$img_dir" "${TUNNEL}" "${builds[@]}"; then
        exit_code=1
    fi
    
    return $exit_code
}

# Execute main function
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
