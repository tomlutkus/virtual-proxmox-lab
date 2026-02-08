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
# Version: 1.1

set -euo pipefail

# Script constants and variables go here
# Status Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Status functions
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
info() { echo -e "${BLUE}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail() { echo -e "${RED}[FAIL]${NC}  $1"; }
status() {
    local label="$1"
    local status="$2"
    local color="$3"
    local width=50
    local dots=$(( width - ${#label} ))
    printf "%s %s %b%s%b\n" "$label" "$(printf '.%.0s' $(seq 1 $dots))" "$color" "$status" "$NC"
}

header() {
    echo -e "${RED}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Virtual Proxmox Lab Teardown"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

footer() {
    echo -e "${GREEN}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Teardown complete. All lab resources removed."
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Functional variables
CONF_DIR="../configs"
IMG_DIR="/var/lib/libvirt/images"
DEL_ISO="false"
NETWORKS=(ceph-br ha-br st-br vm-br)

# Functions
usage() {
    echo "Usage: ${0} [-i] [CONFIG]" >&2
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

# Assign a VM file
VM_FILE="${1:-$CONF_DIR/vm.conf}"

header

# Validation checks
[[ -f "${VM_FILE}" ]] || { fail "Missing VM file: ${VM_FILE}" >&2; exit 1; }

# Script execution
while IFS=',' read -r VM _; do

    info "Removing: ${VM}"

    # Shutdown the VM
    if virsh destroy "${VM}" 2>/dev/null; then
        ok "VM ${VM} stopped"
    else
        warn "VM ${VM} was not running"
    fi

    # Undefine the VM and remove all storage
    if virsh undefine "${VM}" --remove-all-storage 2>/dev/null; then
        status "[VM]    ${VM}" "REMOVED" "${GREEN}"
    else
        status "[VM]    ${VM}" "NOT FOUND" "${YELLOW}"
    fi

    # Delete the ISO if the option was selected
    if [[ "${DEL_ISO}" == "true" ]]; then
        IMG_FILE="${IMG_DIR}/${VM}_automated.iso"

        if [[ -f "${IMG_FILE}" ]]; then
            rm -f "${IMG_FILE}"
            ok "Deleted ISO: ${IMG_FILE}"
        else
            warn "ISO not found: ${IMG_FILE}"
        fi
    fi

done < "${VM_FILE}"

# Shutdown and delete the networks
for NET in "${NETWORKS[@]}"; do

    info "Removing network: ${NET}"

    # Destroy the network
    if virsh net-destroy "${NET}" 2>/dev/null; then
        ok "Network ${NET} stopped"
    else
        warn "Network ${NET} was not running"
    fi

    # Undefine the network
    if virsh net-undefine "${NET}" 2>/dev/null; then
        status "[NET]   ${NET}" "REMOVED" "${GREEN}"
    else
        status "[NET]   ${NET}" "NOT FOUND" "${YELLOW}"
    fi

done

footer

exit 0