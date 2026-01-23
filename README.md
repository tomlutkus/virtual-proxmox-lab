# Virtual Proxmox Lab

This is the repository that goes with my series on building a production-grade virtual Proxmox lab using one PC. We will have automations set for every step of the lab as the project evolves.

You can check my blog out here: https://thomas.lutkus.net/

This is an evolving project, so expect lots of changes and updates to this repo.

## Structure

- `diagrams/` - drawings of the network, virtual network and storage topolgies
- `guests/` - scripts and resource files meant for the guests (Proxmox VMs)
- `host/` - scripts and resouce files meant for the host (you laptop/pc/server)
- `docs/` - Documentation and conventions

## Requirements

- Arch Linux host. I will be experimenting with Ubuntu and Fedora in the future, possibly making versions of some files for those distros too.
- Hardware: 8c/16t CPU, 64GB+ RAM, 1TB+ NVMe storage.
- Proxmox VE 9.1 ISO: https://enterprise.proxmox.com/iso/proxmox-ve_9.1-1.iso

## Important

- Do not experiment on production environments.
- Backup your stuff. Be willing to break and fix things.
- Most importantly: have fun.

## License

GPLv3 - See LICENSE file

I strongly believe in Free Software as defined by the Free Software Foundation, not merely "open source". All code in this repository is and will always be GPL-licensed to ensure these freedoms are preserved for all users.
