#!/bin/bash

# --- VM-PVE-01 Engineered Specs ---
VM_NAME="pve-01"
VM_RAM=20480       # 20GiB
VM_CPU=4
ISO_PATH="$HOME/libvirt/images/pve-01_automated.iso"
IMG_DIR="/var/lib/libvirt/images"

# --- Deployment ---
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
  --network bridge=virbr0,model=virtio,mac=02:00:00:00:01:01 \
  --network bridge=vm-br,model=virtio,mac=02:00:00:01:01:01 \
  --network bridge=ha-br,model=virtio,mac=02:00:00:FD:01:01 \
  --network bridge=ceph-br,model=virtio,mac=02:00:00:FE:01:01 \
  --network bridge=st-br,model=virtio,mac=02:00:00:FF:01:01
