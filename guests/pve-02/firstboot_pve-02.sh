#!/bin/bash

# 1. Disable enterprise repos, enable no-subscription
rm -f /etc/apt/sources.list.d/pve-enterprise.list

cat <<EOF > /etc/apt/sources.list.d/pve-no-subscription.sources
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

cat <<EOF > /etc/apt/sources.list.d/ceph.sources
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# 2. Hosts entries for cluster
cat <<EOF >> /etc/hosts
192.168.122.1 pve-01.lab.local pve-01
192.168.122.2 pve-02.lab.local pve-02
192.168.122.3 pve-03.lab.local pve-03
EOF

# 3. Network config
cat <<EON > /etc/network/interfaces
auto lo
iface lo inet loopback

auto wan
iface wan inet static
    address 192.168.122.2/24
    gateway 192.168.122.254

iface nic_vm inet manual

auto vm_br
iface vm_br inet manual
    bridge-ports nic_vm
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 10,20,30         # 10 = intranet, 20 = dmz, 30 = mgmt

auto ha
iface ha inet static
    address 10.0.253.2/24

auto ceph
iface ceph inet static
    address 10.0.254.2/24

auto store
iface store inet static
    address 10.0.255.2/24
EON

reboot