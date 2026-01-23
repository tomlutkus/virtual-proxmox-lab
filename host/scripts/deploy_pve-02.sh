#!/usr/bin/env bash
#
# Script: deploy_pve-02.sh
# Purpose: Standalone deployment script for pve-02 VM
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
# Usage: ./deploy_pve-02.sh
#
# Author: Thomas Lutkus
# Date: 2026-01-23
# Version: 1.0

set -euo pipefail
# Engineered Specs
VM_NAME="pve-02"
VM_RAM=20480       # 20GiB
VM_CPU=4
ISO_PATH="$HOME/libvirt/images/pve-02-automated.iso"
IMG_DIR="/var/lib/libvirt/images"

# Deployment
virt-install \
  --name "$VM_NAME" \
  --ram "$VM_RAM" \
  --vcpus "$VM_CPU" \
  --cpu host-passthrough \
  --os-variant debian13 \
  --graphics vnc,listen=0.0.0.0 \
  --noautoconsole \
  --boot cdrom,hd \
  --cdrom "$ISO_PATH" \
  --controller type=scsi,model=virtio-scsi \
  --disk path="$IMG_DIR/${VM_NAME}_root.qcow2",size=32,format=qcow2,bus=scsi,cache=none,io=native \
  --disk path="$IMG_DIR/${VM_NAME}_osd1.qcow2",size=150,format=qcow2,bus=scsi,cache=none,io=native \
  --disk path="$IMG_DIR/${VM_NAME}_osd2.qcow2",size=150,format=qcow2,bus=scsi,cache=none,io=native \
  --network bridge=virbr0,model=virtio,mac=02:00:00:00:01:02 \
  --network bridge=vm-br,model=virtio,mac=02:00:00:01:01:02 \
  --network bridge=ha-br,model=virtio,mac=02:00:00:FD:01:02 \
  --network bridge=ceph-br,model=virtio,mac=02:00:00:FE:01:02 \
  --network bridge=st-br,model=virtio,mac=02:00:00:FF:01:02
