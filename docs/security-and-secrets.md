# Security and secrets

## Secrets

Commit only encrypted SOPS files after SOPS/age setup is tested. Never commit the age private key, Restic password, remote storage credentials, reusable Tailscale auth key, SSH private key, rendered Autoinstall user-data, or plaintext .env. Keep at least two secure copies of recovery credentials outside the server. Do not expose secrets in command-line arguments or CI logs. CI secret scans are stop conditions until investigated.

## Network

No public port forwarding or reverse proxy in v1. SSH, Cockpit, Arcane, Beszel, and Kuma are tailnet-only. Bind proxied management apps to loopback where practical and hardware APIs to their LAN address. Review Docker published ports together with firewall rules. Use SSH keys only and disable password login after a second access path is verified.

## Host and containers

Prefer read-only filesystems, tmpfs for ephemeral paths, dropped capabilities, and no-new-privileges where supported. Do not pass the raw Docker socket to ordinary apps. For Arcane, use a deny-by-default socket proxy if it supports the required actions, and verify the allowlist. Keep the host minimal; no desktop, public ingress, Kubernetes, or Fail2ban without a concrete exposed authentication surface.

Disk encryption at boot trades unattended restart for theft protection; defer mandatory passphrase entry unless threat assessment says otherwise. Document the Secure Boot decision and revisit module signing.

## Change protection

Network, Tailscale, SSH, firewall, sudo, storage, Docker, kernel, and NVIDIA changes require reviewed diffs, syntax checks, check/diff preview, alternate access, and second-connection verification.
