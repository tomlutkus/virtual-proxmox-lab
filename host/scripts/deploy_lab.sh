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

# Validation checks
# Check for the VM_FILE
[[ -f "${VM_FILE}" ]] || { echo "Missing VM file: ${VM_FILE}" >&2; exit 1; }

# Check for the network configuration XML files
for NET in "${!NETWORKS[@]}"; do
    FILE="${CONF_DIR}/${NETWORKS[$NET]}"
    [[ -f "${FILE}" ]] || { echo "Missing network file: ${FILE}" >&2; exit 1; }
done

# Define the networks 
for NET in "${!NETWORKS[@]}"; do
    
    echo "Configuring: ${NET}"

    FILE="${CONF_DIR}/${NETWORKS[$NET]}"
    virsh net-define "${FILE}" 2>/dev/null || true
    virsh net-start "${NET}" 2>/dev/null || true
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
    virt-install \
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
      --network bridge=st-br,model=virtio,mac="${MAC_STORE}"

done < "${VM_FILE}"

exit 0