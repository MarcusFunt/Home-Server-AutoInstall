# Ansible

The control machine runs Ansible. The inventory points at reserved address 192.0.2.10 and must be replaced with the verified server address and administrator account.

Dependencies are pinned in requirements.yml and install into ansible/vendor. The playbook intentionally refuses to apply until its roles and checks are implemented.

Implementation order: preflight OS/host/disk/access; create /srv paths and secure base packages; install host Tailscale and verify access; configure Docker/Compose with log rotation; install the supported proprietary NVIDIA driver and toolkit; add Cockpit and acceptance checks.

Keep secrets out of inventory and ordinary group variables. Enable SOPS loading only after age setup and recovery are tested.
