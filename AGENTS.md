# Instructions for coding agents

Read docs/architecture.md, docs/implementation-plan.md, docs/hardware-inventory.md, docs/security-and-secrets.md, docs/operations.md, and docs/recovery.md before changing infrastructure.

## Source of truth

- Treat this repository as the intended state. Do not make undocumented live changes to the server.
- Preserve the user-selected architecture and implementation order. Complete Milestones 1–3 before adding management dashboards or production services.
- Do not invent host-specific values. Use explicit TODOs until hardware, disk serial, network address, tailnet identity, backup target, or credentials have been confirmed.
- Keep versions pinned. A candidate release in versions.yml is not a compatibility result; record actual test evidence before deploying it.

## Safety

- The inventory address is a reserved placeholder. Never target it as a real host.
- Keep deployment_ready false and preserve the playbook/deploy guard until provisioning and acceptance checks are implemented and reviewed.
- Do not run an installer against the production disk, modify host networking, change SSH/firewall/sudo, or deploy infrastructure as part of repository scaffolding.
- Never place plaintext passwords, private keys, SOPS age keys, Restic credentials, reusable Tailscale auth keys, or rendered installer data in Git.
- Do not expose management ports publicly. Review Docker port bindings with the host firewall because Docker-published ports may bypass UFW assumptions.
- For changes affecting Tailscale, SSH, networking, firewall, sudo, storage, Docker, kernel, or NVIDIA, document the alternate access path and rollback; keep the current session open until a second connection succeeds.
- Do not weaken the acceptance gate or remove a guard simply to make CI pass.

## Implementation and validation

- Prefer mature pinned Ansible roles and collections for standard host setup; keep project-specific choices in this repository.
- Use idempotent Ansible, explicit Compose image tags, bind mounts for important state, bounded logs, and documented backup/restore procedures.
- Keep Home Assistant on Home Assistant Green and use direct LAN communication for required local services.
- Run make check and inspect its output. Add meaningful validation for new behavior. Do not claim a full host acceptance test from syntax or lint results.
- Update architecture, operations, version, and recovery documentation when a change alters those decisions.
