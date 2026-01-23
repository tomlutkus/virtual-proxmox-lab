#!/usr/bin/env bash
#
# Script: deploy_lab.sh
# Purpose: Script to deploy the entire Virtual Proxmox Lab
# 
# Copyright (C) 2026 Thomas Lutkus
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Compatibility: distro-agnostic
# Dependencies: libvirt, virt-install
# Requires: qemu:///system access (root or libvirt group)
#
# Usage: ./deploy_lab.sh [VM_FILE]
#
# Author: Thomas Lutkus
# Date: 2026-01-23
# Version: 1.0

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
    echo -e "${BLUE}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Virtual Proxmox Lab Deployment"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

footer() {
    echo -e "${GREEN}"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Deployment complete. VMs installing."
    echo "  Run: virsh start pve-{01,02,03} after install completes"
    echo "═══════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Functional variables
CONF_DIR="../configs"
VM_FILE="${1:-$CONF_DIR/vm.conf}"
declare -A NETWORKS
NETWORKS=(
    [default]="default.xml"
    [ceph-br]="ceph-br.xml"
    [ha-br]="ha-br.xml"
    [st-br]="st-br.xml"
    [vm-br]="vm-br.xml"
)

header

# Validation checks
# Check for the VM_FILE
[[ -f "${VM_FILE}" ]] || { fail "Missing VM file: ${VM_FILE}" >&2; exit 1; }

# Check for the network configuration XML files
for NET in "${!NETWORKS[@]}"; do
    FILE="${CONF_DIR}/${NETWORKS[$NET]}"
    [[ -f "${FILE}" ]] || { fail "Missing network file: ${FILE}" >&2; exit 1; }
done

# Define the networks 
for NET in "${!NETWORKS[@]}"; do
    
    info "Configuring: ${NET}"

    FILE="${CONF_DIR}/${NETWORKS[$NET]}"
    
    # Define the Network
    if virsh net-define "${FILE}" 2>/dev/null; then
        ok "Network ${NET} defined"
    else
        warn "Netowrk ${NET} was already defined"
    fi

    # Start the network
    if virsh net-start "${NET}" 2>/dev/null; then
        ok "Network ${NET} started"
    else
        warn "Network ${NET} already running"
    fi

    # Autostart the network
    virsh net-autostart "${NET}" 2>/dev/null || true
done

# Set the VMs up with the attributes from the VM_FILE
while IFS=',' read -r VM MAC_WAN MAC_VM MAC_HA MAC_CEPH MAC_STORE || [[ -n "$VM" ]]; do    
    
    echo "Deploying: ${VM}"

    # VM Configuration Attributes
    VM_RAM=20480 # 20GiB
    VM_CPU=4
    ISO_PATH="/var/lib/libvirt/images/${VM}_automated.iso"
    IMG_DIR="/var/lib/libvirt/images"
    
    # Check for the ISO file
    [[ -f "${ISO_PATH}" ]] || { echo "Missing ISO: ${ISO_PATH}" >&2; exit 1; }

    # Deploy the VM
    status "[VM]    ${VM}" "DEPLOYING" "${YELLOW}"

    if virt-install \
      --name "${VM}" \
      --ram "${VM_RAM}" \
      --vcpus "${VM_CPU}" \
      --cpu host-passthrough \
      --os-variant debian13 \
      --graphics vnc,listen=0.0.0.0 \
      --noautoconsole \
      --boot cdrom,hd \
      --cdrom "${ISO_PATH}" \
      --controller type=scsi,model=virtio-scsi \
      --disk path="${IMG_DIR}/${VM}_root.qcow2",size=32,format=qcow2,bus=scsi,cache=none,io=native \
      --disk path="${IMG_DIR}/${VM}_osd1.qcow2",size=150,format=qcow2,bus=scsi,cache=none,io=native \
      --disk path="${IMG_DIR}/${VM}_osd2.qcow2",size=150,format=qcow2,bus=scsi,cache=none,io=native \
      --network bridge=virbr0,model=virtio,mac="${MAC_WAN}" \
      --network bridge=vm-br,model=virtio,mac="${MAC_VM}" \
      --network bridge=ha-br,model=virtio,mac="${MAC_HA}" \
      --network bridge=ceph-br,model=virtio,mac="${MAC_CEPH}" \
      --network bridge=st-br,model=virtio,mac="${MAC_STORE}" &>/dev/null; then
        status "[VM]    ${VM}" "OK" "${GREEN}"
    else
        status "[VM]    ${VM}" "FAIL" "${RED}"
    fi

done < "${VM_FILE}"

footer

exit 0