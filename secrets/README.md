# Secrets

This directory may contain encrypted SOPS files ending in .sops.yaml; those encrypted files may be committed. The age private key and plaintext source files must never be committed.

Copy .sops.yaml.example to .sops.yaml only after replacing its example recipient. Back up age and Restic recovery credentials separately. Do not put them on the server or permanent installer USB.

Before enabling Ansible secret loading, verify encryption, decryption, and recovery from a second trusted machine.
