# Implementation plan

Proceed in this order. Do not start with dashboards or applications.

## 1. Repository and inventory

Record motherboard/BIOS, storage models and serials, NIC, GPU, RAM, BIOS power recovery, LAN addressing, and SSH key fingerprint. Confirm the Ubuntu 26.04 image and checksum. Establish SOPS/age and Restic recovery credentials. Back up the repository on a trusted second machine.

Done when inventory and recovery materials have separate secure copies and CI validates the repository.

## 2. Reproducible Ubuntu

Build a minimal Autoinstall image that requires an explicit disk identity. Test in a VM or spare disk first. Verify console recovery and SSH public-key login.

Done when a blank test disk installs from USB and becomes reachable with documented interaction.

## 3. Reproducible base host

Implement idempotent roles for base packages, time, /srv paths, Docker/Compose, host Tailscale, and NVIDIA. Reuse the pinned Geerlingguy Docker role, Artis3n Tailscale collection, and community SOPS collection where suitable. Verify Tailscale before firewall/SSH changes. Configure log rotation and GPU opt-in per service. Keep Pascal driver updates deliberate.

Done when the second Ansible run makes few or no changes, Tailscale and Docker survive reboot, host nvidia-smi works, and a known-good pinned GPU container sees the GTX 1070.

## 4. Management and monitoring

Add Cockpit privately through the tailnet. Deploy Arcane from Git-managed Compose using the narrowest supported Docker API access. Deploy Beszel and Uptime Kuma with pinned images and private exposure. Verify host/container/GPU metrics and service checks.

## 5. Backups and production services

Configure Restic and Restic Profile against off-server storage. Add database-consistent exports, retention, checks, restore verification, and failure monitoring. Move Better Lectio onto the server while Home Assistant stays on the Green; test direct LAN communication. Add other services only with documented data and recovery paths.

## 6. Acceptance and recovery

Complete scripts/verify-host.sh for OS, time, LAN, DNS, Internet, Tailscale, Docker, host/container GPU, Cockpit, Arcane, Beszel, Kuma, production endpoints, and backups. Reboot and test again. Restore a real snapshot to a temporary path. Perform a bare-metal rebuild on a spare disk if available and record every manual step.

## Safety gates

For Tailscale, SSH, network, firewall, sudo, storage, Docker, kernel, and NVIDIA changes: validate syntax, keep the working session open, verify an alternate management path, apply, open a second connection, and rerun acceptance. Do not close the old path until the second connection works.

## Definition of done

A reviewed USB installs the OS; Ansible reproduces the host; remote access, Docker, and GPU work after reboot; Cockpit/Arcane/Beszel/Kuma support daily operations; Better Lectio uses direct LAN communication with HA Green; off-server backups have passed restore tests; management is not public; versions and secrets are controlled; and a bare-metal recovery has been exercised.
