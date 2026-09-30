# Home Server AutoInstall

Infrastructure as code for the GTX 1070 home-server appliance: reproducible, remotely manageable, observable, backed up, and rebuildable.

## Agreed architecture

- Ubuntu Server 26.04 LTS on bare metal, after validating the official image and hardware compatibility.
- Ubuntu Autoinstall for base OS installation; Ansible for idempotent host configuration.
- Docker Compose for services. Compose definitions live under /srv/stacks and persistent state under /srv/data.
- GTX 1070 uses NVIDIA's proprietary Pascal driver and NVIDIA Container Toolkit. GPU access is opt-in by service; upgrades require compatibility and reboot tests.
- Tailscale runs on the host. No public management ports or router port forwarding.
- Cockpit manages Ubuntu. Arcane operates Git-managed Compose projects. Git remains the source of truth.
- Beszel reports host, container, and GPU resources. Uptime Kuma checks service reachability.
- Restic and Restic Profile back up persistent state off-server and support scheduled restore verification.
- SOPS and age protect secrets in Git. Recovery keys and backup credentials stay outside the server and repository.
- Home Assistant stays on Home Assistant Green and communicates with server workloads directly over Ethernet.

## Current state

This is a scaffold, not a deployable server configuration. The playbook and deploy command intentionally stop. Inventory, disk identity, Autoinstall inputs, secrets, NVIDIA compatibility, Compose projects, and full acceptance checks must be completed and tested first. Do not point an installer at the server disk until the hardware inventory has been reviewed.

## Repository map

- autoinstall: installer design and safe build requirements.
- ansible: inventory, pinned dependencies, and guarded entry point.
- docs: architecture, implementation order, operations, security, hardware, and recovery.
- secrets: SOPS setup guidance and nonfunctional example.
- stacks: future Git-managed Compose projects.
- scripts: deployment guard and validation/acceptance scaffolding.
- versions.yml: candidate releases observed 2026-09-30; not tested on this host.

Run make check before changes are proposed. CI repeats validation on pull requests. The deploy target stays blocked until commissioning gates in docs/implementation-plan.md are satisfied.

First complete Milestones 1–3: inventory, secure Autoinstall, repeatable base host, Tailscale, Docker, and GTX 1070 support. Add dashboards and production applications after that foundation survives reboot.
