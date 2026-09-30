# Hardware inventory

Complete this before generating a destructive installer or host-specific Ansible.

## Machine

- Hostname: choose.
- Motherboard and revision: record.
- BIOS version/date: record.
- CPU and RAM: record.
- GPU: NVIDIA GeForce GTX 1070; confirm exact board and VRAM.
- Secure Boot state: record.
- BIOS Restore on AC Power Loss: set to Power On where supported.
- Disable sleep and suspend.

## Storage

For every drive, record model, serial, capacity, bus, SMART/NVMe health, role, and whether it can be erased. Record the boot SSD's exact identity and stable device ID. Record data/backup drives separately; same-machine storage is not the primary backup.

Do not use “largest disk” as the install target. Match an explicit serial or reviewed stable ID.

## Network and access

- Ethernet NIC model and MAC: record.
- Router/gateway and DNS: record.
- DHCP reservation or static address: choose.
- LAN interface and server IP: record.
- Tailnet hostname/tag: choose.
- SSH public-key fingerprint: record; never store private key.
- Local keyboard/display break-glass access: confirm.

## Power and recovery

- Automatic power-on after outage: confirm BIOS setting.
- UPS: optional for v1; record if present.
- Installer USB/checksum: record after creation.
- Off-server backup target: required before production migration.
