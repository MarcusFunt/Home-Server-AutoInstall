# Recovery runbook

## Keep outside the server and Git

Maintain separate secure copies of the infrastructure repository, age private key/passphrase, Restic password and remote credentials, administrator SSH key, verified installer/checksum, hardware inventory, and BIOS settings. Losing the age key or Restic password can make encrypted data unrecoverable.

## Tailscale unavailable

Use local keyboard/display as break-glass access. Check systemd, time, DNS, and the Tailscale service. Reapply reviewed Ansible only after confirming LAN access. Verify a second remote connection before closing current sessions.

## NVIDIA driver broken

Boot the previous kernel or recovery mode. Restore the documented known-good driver/kernel combination, reboot, then test host and container GPU access. Avoid blind upgrades during recovery.

## Docker broken

Restore the Ansible-controlled daemon configuration from Git, validate it, restart Docker, and redeploy Compose from Git. Do not delete /srv/data while repairing containers.

## Application or database failure

Inspect Kuma, Arcane, and application logs. Preserve current data before changing database state. Restore using an application-specific procedure or to a temporary directory with Restic. Confirm the database opens before replacing production data.

## Boot SSD failure

Replace the SSD, boot the verified installer, install to the inventoried target, configure via Ansible, restore /srv/data from off-server Restic, and run host, service, and GPU acceptance.

## Bad infrastructure change

Revert the offending Git commit, run CI and Ansible check/diff, then apply the reviewed state. Keep a working path open and verify a second connection.

## Rebuild exercise

After v1 stabilizes, rebuild on a spare disk if available. Record each manual action; automate repeatable steps or document unavoidable ones. Restore a selected snapshot to a temporary directory and verify its contents.
