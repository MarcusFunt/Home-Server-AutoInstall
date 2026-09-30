# Reproducible Home Server Implementation Plan

> **For agentic workers:** Use the executing-plans workflow and complete one task at a time. Keep each task reviewable; do not deploy until its gates are satisfied.

**Goal:** Turn the GTX 1070 computer into a reproducible Ubuntu home server with verified remote administration, LAN access for local integrations, containerized workloads, monitoring, and tested off-server recovery.

**Architecture:** Ubuntu Server 26.04 LTS is installed from a guarded Autoinstall image and configured idempotently with Ansible. Docker Compose runs pinned services with persistent data under /srv; Tailscale provides remote administration while local devices communicate over the physical LAN. Cockpit and Portainer provide administration, Beszel and Uptime Kuma provide monitoring, and Restic provides off-server backups.

**Tech Stack:** Ubuntu Autoinstall, Ansible, Docker Engine and Compose, NVIDIA proprietary driver and Container Toolkit for Pascal, Tailscale, Cockpit, Portainer, Beszel, Uptime Kuma, SOPS/age, Restic/Restic Profile, GitHub Actions.

**Spec:** README.md, docs/architecture.md, docs/implementation-plan.md, docs/hardware-inventory.md, docs/security-and-secrets.md, docs/operations.md, docs/recovery.md.

## Global Constraints

- Keep the Ansible safety flag false until commissioning and acceptance gates are complete.
- Never use a guessed disk target; match the reviewed boot-drive serial or stable device ID.
- Keep management services private; do not add public port forwarding.
- Use Tailscale for remote administration and the server's wired LAN address for local integrations such as Home Assistant Green.
- Keep Home Assistant on Home Assistant Green.
- Pin software and image versions; a candidate version is not host compatibility evidence.
- Keep passwords, age private keys, backup credentials, Tailscale reusable auth keys, and rendered Autoinstall data out of Git.
- Do not change SSH, firewall, routing, storage, kernel, Docker, or NVIDIA remotely until an alternate access path is verified.
- Run lint, syntax, Compose validation, secret scanning, and applicable host acceptance checks before each review.
- Do not migrate production data until an off-server backup has passed a restore test.

## Review Focus

- A wrong disk identifier could erase the wrong drive; test that unknown and mismatched IDs abort before installation.
- A missing Tailscale connection could lock out a headless server; prove local break-glass access and a second remote connection before restricting SSH or firewall rules.
- Docker-published ports can bypass assumptions about UFW; inspect effective bindings and test from LAN, tailnet, and an external network.
- GTX 1070 support depends on the exact Ubuntu kernel, NVIDIA driver, toolkit, and container; test the complete pinned tuple before service deployment and again after reboot.
- A successful Restic snapshot does not prove recovery; restore application data and configuration to a temporary location and verify that they can be opened.

---

## Task 1: Commission the hardware and freeze decisions

**Files:**
- Modify: docs/hardware-inventory.md
- Modify: docs/architecture.md
- Modify: README.md
- Create: docs/commissioning-record.md

**Decisions to record:**
- Confirm the server hostname, motherboard and BIOS, CPU/RAM, exact GTX 1070 board, Secure Boot state, and automatic power-on after outage.
- Record every drive's model, serial, capacity, bus, health, intended role, and whether it may be erased. Mark one reviewed install target.
- Record the wired NIC, LAN interface, DHCP reservation or static address, gateway, DNS, and how the server will reach Home Assistant Green.
- Confirm local keyboard/display recovery, current data to preserve, SSH public-key fingerprint, and the off-server backup destination.
- Use Portainer as the current management-UI choice. Remove the repository's Arcane references and candidate version entry only after this decision is confirmed in the commissioning record.
- Record the rule that management access is tailnet-only while local service traffic uses the wired LAN.

**Verification:**
- Review the inventory with the physical machine present.
- Check that the documented install-disk serial matches the drive firmware or OS inventory.
- Check that no private key, password, Tailscale auth key, or backup credential appears in the record.
- Search the repository for Arcane and replace stale references consistently before adding Portainer files.

**Done when:** The install target, network plan, recovery route, service manager, data-preservation decision, and backup destination are recorded, and a second trusted copy of the repository exists.

## Task 2: Make repository checks reflect real deployable content

**Files:**
- Modify: Makefile
- Modify: .github/workflows/validate.yml
- Modify: scripts/check-secrets.sh
- Modify: scripts/validate-compose.sh
- Modify: ansible/requirements.yml
- Create as needed: tests/ or ansible/tests/

**Work:**
- Keep YAML lint, Ansible lint, shell lint, syntax checks, Compose config validation, and secret-marker scan in the required pull-request workflow.
- Ensure Compose validation fails if a Compose file exists but Docker Compose validation fails. Keep the current no-files case explicitly labelled as a skip.
- Add a test that the deployment guard still refuses to run while deployment_ready is false.
- Add tests for reserved inventory placeholders and invalid disk identifiers once preflight is implemented.
- Ensure CI installs the same pinned Ansible roles and collections used by local validation; avoid making CI depend on decrypted secrets or a live server.
- Keep vendored Ansible dependencies out of Git.

**Verification:**
- Run make check locally from a clean checkout.
- Deliberately introduce a temporary malformed YAML, shell syntax error, bad Compose file, and known test secret marker in an isolated test fixture; confirm each relevant check fails, then remove the fixture.
- Confirm the workflow passes without silently claiming a Compose or host test ran.

**Done when:** CI gives a clear pass/fail/skip for every repository-level check and catches the expected negative cases.

## Task 3: Establish recoverable secrets and access materials

**Files:**
- Modify: secrets/README.md
- Modify: secrets/.sops.yaml.example
- Modify: docs/security-and-secrets.md
- Modify: docs/recovery.md
- Create: local ignored age-key and inventory setup instructions, without committing key material

**Work:**
- Generate an age keypair on a trusted workstation, not on the server.
- Store the private key and passphrase in two separately controlled offline recovery locations.
- Replace the example public recipient in the local SOPS configuration and verify encrypt/decrypt/re-encrypt from a second trusted machine.
- Store only encrypted service credentials in SOPS once actual credentials exist. Keep the Restic password and remote repository credentials recoverable separately.
- Choose how the first Tailscale enrollment will happen: one-time interactive enrollment or a short-lived, narrowly scoped auth key injected locally and removed afterward.
- Write a rotation and loss-recovery procedure. Do not create placeholder production credentials.

**Verification:**
- Encrypt a harmless fixture, decrypt it on a second machine, and confirm that Git contains only ciphertext.
- Confirm the private age key and plaintext fixture are ignored and absent from tracked files.
- Confirm the recovery runbook identifies which credential unlocks each encrypted data set.

**Done when:** Secret encryption and recovery have been exercised independently of the server.

## Task 4: Build and test a guarded Ubuntu Autoinstall

**Files:**
- Modify: autoinstall/README.md
- Create: autoinstall/user-data.template
- Create: autoinstall/build.sh
- Create: autoinstall/validate.sh
- Modify: .gitignore
- Create: tests/autoinstall/fixtures/ for safe test inputs

**Work:**
- Select and record the official Ubuntu Server 26.04 image, checksum, and installation method after checking current hardware and NVIDIA support.
- Generate user-data from non-secret templates and local ignored inputs. The committed template must not contain a real password hash, SSH private key, age key, or backup credential.
- Require a configured boot-drive serial or stable identifier; abort if it is missing, duplicated, or differs from the reviewed target. Never select “largest disk.”
- Keep the first bare-metal installation confirmation explicit. Use a disposable VM or spare drive for destructive installer tests.
- Configure a minimal base OS, SSH public-key access, a named administrator, hostname, and wired networking. Leave host service setup to Ansible.
- Keep rendered user-data and ISO output in ignored directories and show their paths clearly.

**Verification:**
- Validate the rendered Autoinstall document against the selected Ubuntu release's schema.
- Build the installer and verify the source ISO checksum before modification.
- Run the installer in a VM with a disposable disk; verify the resulting OS version, hostname, SSH key login, and console recovery.
- Test missing and mismatched disk serial inputs and confirm the build/install process stops before writing.

**Done when:** A disposable target installs reproducibly and the production disk cannot be selected by an implicit default.

## Task 5: Implement Ansible preflight and base host roles

**Files:**
- Modify: ansible/playbooks/site.yml
- Modify: ansible/inventory/hosts.yml
- Modify: ansible/group_vars/all.yml
- Create: ansible/roles/preflight/
- Create: ansible/roles/base/
- Create: ansible/roles/storage/
- Create: ansible/roles/access/

**Interfaces:**
- The site playbook must run preflight before any mutating role.
- Local host-specific values belong in an ignored inventory overlay, not committed group defaults.
- Preflight must reject the reserved 192.0.2.10 address, REPLACE_WITH_ADMIN_USER, the wrong host, unexpected OS version, and an unreviewed boot-disk identity.
- deployment_ready remains false until the final acceptance gate.

**Work:**
- Implement read-only preflight checks for host identity, Ubuntu release, reachability, available storage, disk identifiers, and required local access.
- Implement idempotent timezone/time configuration, baseline packages and updates policy, power/suspend settings, and required /srv directory creation.
- Mount only explicitly inventoried data filesystems by UUID. Do not repartition or format as part of ordinary Ansible.
- Configure SSH keys and sudo only after confirming a second access path. Keep password login changes in a separate, reviewed step.
- Keep roles small and named for the resource they own. Use handlers for service restarts.

**Verification:**
- Run ansible-lint and syntax check.
- Run preflight against test inventories: valid host passes; placeholder host, wrong OS, wrong disk identity, and missing recovery access fail without changing the host.
- Run base roles twice in an isolated test machine; the second run must report no unexpected changes.
- Inspect the Ansible diff before any real application.

**Done when:** The base OS can be configured repeatably, and unsafe or uncommissioned inventory fails before mutation.

## Task 6: Establish Tailscale before remote hardening

**Files:**
- Create: ansible/roles/tailscale/
- Modify: ansible/playbooks/site.yml
- Modify: docs/operations.md
- Modify: docs/recovery.md

**Work:**
- Install and configure host Tailscale using the pinned collection and an enrollment method chosen in Task 3.
- Use a stable tailnet hostname and document the node ownership and key-expiry policy.
- Keep the wired LAN interface and direct LAN routes available. Do not route Home Assistant traffic through Tailscale.
- Expose administration over the tailnet. Do not add router forwarding or public reverse proxies.
- Delay firewall and SSH restrictions until tailnet reachability has been tested from another device.

**Verification:**
- Confirm the server appears in the tailnet with the expected identity.
- From a separate device, connect over cellular or another off-LAN network and establish a second SSH or management session.
- Confirm the server and Home Assistant Green communicate over their wired LAN addresses.
- Reboot the server and repeat both remote and local connectivity checks.
- Confirm an enrollment key is not left in process output, shell history, logs, or Git.

**Done when:** A second remote path works after reboot and the local LAN path remains independent.

## Task 7: Configure Docker, Compose, storage paths, and network boundaries

**Files:**
- Create: ansible/roles/docker/
- Modify: ansible/group_vars/all.yml
- Create: ansible/templates/daemon.json.j2
- Create: ansible/templates/docker-logrotate.conf.j2
- Create: ansible/tests/ for daemon and port-binding policy
- Create: stacks/README.md examples or validation fixtures

**Work:**
- Install Docker Engine and Compose v2 through the pinned role or a documented equivalent.
- Configure bounded container logs, restart behavior, and storage locations; keep Docker's internal layer store rebuildable and persistent application state under /srv/data.
- Create /srv/stacks, /srv/data, /srv/backups, /srv/cache, and /srv/scratch with explicit ownership and permissions.
- Require explicit loopback, tailnet, or LAN bind addresses in Compose. Reject 0.0.0.0 for management services.
- Document Docker firewall behavior and configure host filtering with rules that preserve established remote access.
- Do not put production service credentials in Compose files; inject them from protected files or an approved SOPS decryption step.

**Verification:**
- Check Docker daemon configuration before restart.
- Run a harmless test container and a test Compose project.
- Inspect listening sockets and test each exposed port from LAN, tailnet, and an external network.
- Reboot and confirm Docker and the data mounts return in the expected order.
- Confirm logs are bounded and important application files are not under Docker's disposable image layers.

**Done when:** Docker and Compose survive reboot, persistent paths are clear, and no management port is reachable from the public internet.

## Task 8: Enable the GTX 1070 for host and container workloads

**Files:**
- Create: ansible/roles/nvidia/
- Modify: versions.yml
- Modify: docs/version-policy.md
- Modify: scripts/verify-host.sh
- Create: tests/nvidia/ compatibility notes and expected outputs

**Work:**
- Verify the current Ubuntu kernel, proprietary Pascal driver support, NVIDIA Container Toolkit compatibility, and a container image that still supports the GTX 1070's compute capability.
- Record one tested tuple: Ubuntu release/kernel, driver package, Container Toolkit version, and GPU test image digest.
- Install the driver in a separate change from firewall or SSH changes. Do not use the open kernel module for this Pascal card.
- Keep GPU access opt-in; only Compose services that need it receive NVIDIA device access.
- Pin test image by digest or immutable tag; do not use latest.

**Verification:**
- Confirm the host reports the GTX 1070 with nvidia-smi.
- Run the pinned GPU test container and confirm it sees the GPU and can execute a small CUDA operation.
- Reboot and repeat both checks.
- Test rollback to the previously bootable kernel/driver path before declaring the GPU milestone complete.

**Done when:** The exact tested software tuple works on the host and in a container after reboot and has a documented rollback.

## Task 9: Deploy host management and Docker management

**Files:**
- Create: ansible/roles/cockpit/
- Create: stacks/portainer/compose.yaml
- Create: stacks/portainer/README.md
- Modify: docs/architecture.md
- Modify: docs/operations.md
- Modify: scripts/verify-host.sh

**Work:**
- Install Cockpit for Ubuntu administration and Portainer for Docker administration; choose and pin a tested Portainer edition and version.
- Keep both interfaces reachable only through the tailnet. Use the narrowest documented Docker API access Portainer supports; document the API permissions and risk before enabling them.
- Persist Portainer configuration under /srv/data and keep the stack definition in Git.
- Make Git the source of truth. Document whether Compose projects are deployed from Git checkout or Portainer's Git integration; test updates and rollback using that same path.
- Add health checks where the upstream service supports them and bound logs.

**Verification:**
- Confirm both interfaces load from a tailnet device and fail from a public external network.
- Confirm a Portainer restart does not lose endpoints, users, or stack state.
- Change one harmless Compose setting in Git, deploy it through the documented path, and revert it.
- Confirm the raw Docker socket is not mounted unless an explicit reviewed decision requires it.

**Done when:** Both management tools work remotely without public exposure and a service can be redeployed from Git after restart.

## Task 10: Add monitoring and alerting

**Files:**
- Create: stacks/beszel/compose.yaml
- Create: stacks/uptime-kuma/compose.yaml
- Create: stacks/beszel/README.md
- Create: stacks/uptime-kuma/README.md
- Modify: docs/operations.md
- Modify: scripts/verify-host.sh

**Work:**
- Deploy Beszel Hub and agent with persistent state and only the host/container metrics needed for v1.
- Deploy Uptime Kuma with persistent monitor state.
- Restrict both management interfaces to the tailnet.
- Add checks for host reachability, Tailscale, Docker, management endpoints, GPU test endpoint, backup freshness, and the later production service.
- Configure a notification destination and test its failure and recovery notifications.
- Do not claim GPU monitoring until a real metric is shown on the dashboard.

**Verification:**
- Validate every Compose project with docker compose config.
- Confirm Beszel receives host and container metrics after reboot.
- Confirm GPU data appears if the chosen agent/plugin supports it; otherwise document the specific limitation and monitor GPU health through a separate verified check.
- Stop a test service and confirm Kuma detects failure, then restart it and confirm recovery.
- Confirm monitors do not report stale cached success as current health.

**Done when:** A real stopped service and a real recovered service produce verified alert transitions.

## Task 11: Configure off-server backups and prove restore

**Files:**
- Create: ansible/roles/restic/
- Create: stacks/restic-profile/ or host systemd units, after choosing the execution model
- Modify: secrets/README.md
- Modify: docs/security-and-secrets.md
- Modify: docs/operations.md
- Modify: docs/recovery.md
- Create: scripts/verify-backup.sh

**Work:**
- Select an off-server repository and record its network, account, capacity, retention, and recovery ownership.
- Encrypt backups with Restic. Keep the repository password and remote credentials in SOPS/local protected files and separate recovery copies.
- Back up /srv/data and required machine configuration; exclude caches, scratch, Docker image layers, and reproducible downloads.
- Add application-consistent database exports before backup and retention/prune only after confirming a good snapshot.
- Schedule backups with bounded logs and visible failure alerts. Avoid overlapping backup and prune jobs.
- Define a restore target under a temporary path so verification never overwrites production state.

**Verification:**
- Run the first snapshot and list its contents.
- Run Restic integrity checks and confirm the expected source paths exist.
- Restore a representative service and its database to a temporary directory; open/validate the restored data using the service's own tool.
- Simulate missing credentials and unavailable remote storage; confirm the job fails visibly and monitoring reports the failure.
- Confirm backup age alert triggers when the last successful snapshot is stale.

**Done when:** A representative service can be restored from the off-server repository with documented credentials and no production overwrite.

## Task 12: Migrate the first production service and validate LAN integration

**Files:**
- Create: stacks/<service>/compose.yaml
- Create: stacks/<service>/README.md
- Modify: docs/operations.md
- Modify: docs/recovery.md
- Modify: scripts/verify-host.sh
- Add service-specific import/export scripts only where required

**Work:**
- Choose the first production workload, document its data paths, ports, health check, dependencies, backup method, and rollback.
- For Better Lectio, keep Home Assistant on Home Assistant Green and use the server's wired LAN address for HA integration traffic.
- Deploy first with test or copied data; verify service behavior before moving authoritative data.
- Migrate production data only after Task 11 restore succeeds.
- Keep services without a recovery path out of the production stack.

**Verification:**
- Check the service from a LAN client and, where intended, through tailnet remote access.
- Confirm HA Green reaches the service directly over the wired LAN.
- Stop/restart the service, reboot the host, and verify health and data persistence.
- Restore the service into a temporary location and confirm the documented recovery steps still work.

**Done when:** The first production service has a tested deployment, LAN path, rollback, and restore procedure.

## Task 13: Complete host acceptance and recovery exercise

**Files:**
- Modify: scripts/verify-host.sh
- Modify: scripts/deploy.sh
- Modify: docs/implementation-plan.md
- Modify: docs/operations.md
- Modify: docs/recovery.md
- Modify: README.md

**Work:**
- Split host verification into explicit foundation and full profiles. The full profile must fail when any required check is unset or skipped.
- Check OS, time, storage mounts, LAN/gateway/DNS/internet, Tailscale, Docker/Compose, host and container GPU, Cockpit, Portainer, Beszel, Kuma, production endpoints, backup freshness, and Restic integrity.
- Add a deployment preflight that checks inventory identity, deployment_ready, required encrypted secrets, repository cleanliness, and an Ansible check/diff preview. Keep deployment blocked until all acceptance criteria are satisfied.
- Perform a controlled reboot with local break-glass available. Verify a second remote connection before closing the original.
- Rebuild on a spare disk if available and record manual steps. Do not use the production boot disk for the first rebuild exercise.
- Only after all gates pass, change deployment_ready in a separate reviewed commit and remove the scaffold refusal in a separate reviewed change.

**Verification:**
- Run make check and the full host profile.
- Reboot, then rerun the full host profile.
- Restore a real snapshot to a temporary path.
- Perform and document the spare-disk rebuild if hardware is available.
- Test that deploy still refuses when any safety gate is false.

**Done when:** A reviewed USB and Ansible reproduce the host; remote and LAN paths survive reboot; GPU, management, monitoring, and backups pass; and a restore/rebuild has been exercised.

## Release gates

1. Do not generate a production installer until the physical boot disk and data-preservation decision are recorded.
2. Do not harden SSH or firewall until Tailscale and local break-glass access both work.
3. Do not install NVIDIA drivers until the exact Ubuntu/kernel/driver/toolkit/container tuple is checked.
4. Do not move production data until off-server restore is proven.
5. Do not remove the deployment guard until the full post-reboot acceptance profile passes.
