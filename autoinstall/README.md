# Ubuntu Autoinstall

Autoinstall installs a clean base Ubuntu Server system, administrator account, SSH key, and basic networking. Ansible owns all later host configuration.

Do not add an unattended disk target until the hardware inventory records the boot disk model, serial, capacity, and tested stable identifier. The first install must confirm the disk interactively or by explicit serial match. Never assume the largest disk is the boot disk.

Generate installer inputs from local values that are not committed. Keep the age private key, Restic password, reusable Tailscale auth key, and plaintext credentials off permanent USB media.

Build flow: verify the official Ubuntu ISO checksum, render user-data from validated local inputs, build and inspect the installer, test in a VM or spare disk, then perform the bare-metal installation. Put rendered files and ISO output in ignored directories.
