#!/usr/bin/env bash
#
# Script: destroy_lab.sh
# Purpose: Script to tear down the whole Virtual Proxmox Lab easily.
# 
# Copyright (C) 2026 Thomas Lutkus
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Dependencies: libvirt
# Requires: qemu:///system access (root or libvirt group)
#
# Usage: ./destroy_lab.sh [-i] [CONFIG]
#
# Author: Thomas Lutkus
# Date: 2026-01-23
# Version: 1.0

set -euo pipefail

# Script constants and variables go here
CONF_DIR="../configs"
IMG_DIR="/var/lib/libvirt/images"
DEL_ISO="false"
NETWORKS=(ceph-br ha-br st-br vm-br)

# Functions
usage() {
    echo "Usage: ${0} [-i]" >&2
    echo "  -i  Also delete the custom ISO files" >&2
    exit 1
}

# Process script options
while getopts "i" OPTION
do
    case $OPTION in
    i) DEL_ISO="true" ;;
    *) usage ;;
    esac
done

# Shift the option away
shift $((OPTIND - 1))

# Assign a VM file file 
VM_FILE="${1:-$CONF_DIR/vm.conf}"

# Script execution
while IFS=',' read -r VM _; do
    
    echo "Removing: ${VM}"

    # Shutdown and delete the VM and all files
    virsh destroy "${VM}" 2>/dev/null || true
    virsh undefine "${VM}" --remove-all-storage 2>/dev/null || true

    # Delete the ISO if the option was selected
    if [[ "${DEL_ISO}" == "true" ]]    
    then
        IMG_FILE="${IMG_DIR}/${VM}_automated.iso"
        
        echo "Deleting the ISO ${IMG_FILE}"
        
        rm -f "${IMG_FILE}"
    fi
done < "${VM_FILE}"

# Shutdown and delete the networks
for NET in "${NETWORKS[@]}"; do
    
    echo "Removing network ${NET}"

    virsh net-destroy "${NET}" 2>/dev/null || true
    virsh net-undefine "${NET}" 2>/dev/null || true
done

exit 0