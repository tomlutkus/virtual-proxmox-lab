#!/usr/bin/env bash
#
# Script: create_iso.sh
# Purpose: Simple script to make the process of creating automated PVE installation ISO portable
# 
# Copyright (C) 2026 Thomas Lutkus
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Compatibility: Debian 13 (must run inside Distrobox on Arch Linux)
# Dependencies: proxmox-auto-install-assistant
# https://pve.proxmox.com/wiki/Automated_Installation#Assistant_Tool
# Requires: root
#
# Usage: ./create_iso.sh [PVE_NODE]
#
# Author: Thomas Lutkus
# Date: 2026-01-22
# Version: 1.3

set -euo pipefail

# Script constants and variables go here
NODE="${1:-}"
ISO_FILE="/var/lib/libvirt/images/proxmox-ve_9.1-1.iso"
ANSWER_FILE="${NODE}/answer_${NODE}.toml"
FIRST_BOOT="${NODE}/firstboot_${NODE}.sh"
OUTPUT="/var/lib/libvirt/images/${NODE}_automated.iso"


# Verifications to run the script
# Check usage
if [[ -z "${NODE}" ]]
then
    echo "Usage: ${0} [pve-NN]" >&2
    echo "Missing a pve node as argument." >&2
    exit 1
fi

# Check for super user privileges
# if [[ "${UID}" -ne 0 ]]
# then
#     echo "ERROR: Must run as root." >&2
#     exit 1
# fi

# Check for Debian 13
if ! grep -qi 'trixie' /etc/os-release
then
    echo "ERROR: Requires Debian 13 (Trixie)." >&2
    exit 1
fi

# Check for the assistant tool
if ! dpkg-query -W proxmox-auto-install-assistant &>/dev/null
then
    echo "ERROR: Missing proxmox-auto-install-assistant package." >&2
    echo "Please refer to https://pve.proxmox.com/wiki/Automated_Installation for more information." >&2
    exit 1
fi

proxmox-auto-install-assistant prepare-iso "${ISO_FILE}" \
   --fetch-from iso \
   --answer-file "${ANSWER_FILE}" \
   --on-first-boot "${FIRST_BOOT}" \
   --output "${OUTPUT}"

EXIT_STATUS="${?}"

if [[ "${EXIT_STATUS}" -ne 0 ]]
then
    echo "The script did not execute successfully!" >&2
    exit "${EXIT_STATUS}"
fi

exit 0
