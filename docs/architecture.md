# Architecture

## Goal and platform

Operate the spare GTX 1070 computer as an appliance whose intended state is in Git, important state is backed up elsewhere, and OS can be rebuilt.

Ubuntu Server 26.04 LTS on bare metal is the target, subject to validating the official image, support window, motherboard/NIC, and NVIDIA driver. Autoinstall installs the OS; Ansible configures the host repeatably. Docker Compose is the application runtime. Proxmox, Kubernetes, k3s, desktop Linux, and multiple VMs are out of scope for v1.

Use ext4 initially. Organize /srv/stacks for Compose, /srv/data for application state, /srv/backups for optional local copies, /srv/cache for rebuildable cache, and /srv/scratch for disposable work. Docker internal storage is rebuildable and is not the primary backup target. Prefer bind mounts for important state; document recovery for named volumes.

## GPU

The GTX 1070 is Pascal. Use the proprietary NVIDIA driver, not the newer open kernel module. Install NVIDIA Container Toolkit and grant GPU access only to workloads that need it. Record a tested tuple of Ubuntu kernel, NVIDIA driver, toolkit, and CUDA container. Review Pascal and kernel compatibility, test host and container access, reboot, and rerun acceptance before upgrades.

## Network and management

Tailscale runs directly on Ubuntu. No router port forwarding. Administrative interfaces are tailnet-only. Bind Tailscale-proxied applications to loopback where practical. Bind hardware-facing APIs to their specific LAN IP. Docker published ports must be reviewed alongside the host firewall because UFW alone may not control them.

Internet: no administrative services. Tailnet: Cockpit, Arcane, Beszel, Uptime Kuma, SSH. LAN: only required hardware endpoints, including Better Lectio to Home Assistant. Home Assistant remains on Home Assistant Green; use direct Ethernet for local traffic.

Cockpit manages host storage, networking, updates, services, logs, files, reboots, and emergency terminal access. Arcane handles Docker operations and Git-backed deployments; Git remains the permanent configuration source. Use a deny-by-default Docker socket proxy where Arcane supports the required operations.

## Observability and recovery

Beszel tracks host, container, and GPU resources. Uptime Kuma tests whether services respond. Restic with Restic Profile backs up /srv/data and irreplaceable machine configuration to an off-server repository. Use application-aware database exports, retention, integrity checks, backup-age alerts, and restore tests.

SOPS encrypts configuration for Git. Age private keys and Restic credentials stay separate. Do not require an interactive boot-unlock passphrase in v1 unless theft risk outweighs autonomous reboot. Record the Secure Boot decision; it may initially be disabled to simplify NVIDIA module setup.

## Workflow

Change in Git, review diff, CI, Ansible check/diff, apply, acceptance tests. Changes to networking, Tailscale, SSH, firewall, sudo, Docker, storage, kernel, or NVIDIA need an alternate access path and a second verified connection before success.
