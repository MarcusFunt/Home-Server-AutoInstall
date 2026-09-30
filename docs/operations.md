# Operations

## Daily interfaces

- Beszel: CPU, memory, disk, network, containers, GPU.
- Uptime Kuma: whether applications respond.
- Arcane: container logs, status, images, Compose operations, restart.
- Cockpit: Ubuntu updates, storage, networking, systemd, logs, files, shutdown, reboot.
- Git: permanent configuration changes. Do not make a GUI edit the only source of truth.

## Change workflow

1. Make a small Git change and review the diff.
2. Run make check and inspect CI.
3. For host changes, run Ansible check and diff against verified inventory.
4. Apply only after understanding the preview.
5. Run acceptance checks. For high-risk changes, leave the current session open and confirm a second connection.
6. Update operational and recovery documentation with the change.

## Updates

Apply application updates deliberately from pinned Compose tags and verify health. Apply OS security updates under a controlled reboot policy. Kernel, NVIDIA driver, Docker major, Tailscale policy, storage, firewall, and network changes require the full acceptance suite and reboot test.

## Alerts and backups

Start with host unreachable, disk above 85%, sustained RAM above 90%, excessive GPU temperature, unexpected container stop, stale/failed backup, repository-check failure, and restore-verification failure. Tune against actual normal behavior.

Run Restic checks and periodic restore tests. A recent snapshot alone does not prove recoverability.
