# Home Server Minimal Bootstrap and Implementation Plan

> **For agentic workers:** Use the executing-plans workflow and complete one task at a time. Keep each task reviewable; do not deploy until its gates are satisfied.

**Goal:** Install and configure the GTX 1070 computer as a rebuildable home server with a full remote desktop, reliable tailnet administration, local LAN integration, monitored container services, and tested off-server recovery.

**Architecture:** A USB builder runs on the user's trusted computer, generates and displays a random hostname, verifies the official installer image, and writes a guarded Ubuntu Autoinstall USB. The installer pauses on the target machine for the drive, identity, and network questions that require human input; after first boot, a local bootstrap command records discoverable machine details and asks only for unresolved interactive choices. Ansible then configures Ubuntu Server, Tailscale, Docker, the GTX 1070, a lightweight remote desktop, administration, monitoring, and backups.

**Tech Stack:** Ubuntu Server 26.04 LTS, Ubuntu Autoinstall/Subiquity, Ansible, Docker Engine and Compose, NVIDIA proprietary Pascal driver and Container Toolkit, Tailscale, XFCE with xrdp as the first desktop candidate, Cockpit, Arcane, Beszel, Uptime Kuma, SOPS/age, Restic/Restic Profile.

**Spec:** README.md, docs/architecture.md, docs/implementation-plan.md, docs/hardware-inventory.md, docs/security-and-secrets.md, docs/operations.md, docs/recovery.md, and the user decisions recorded in this plan.

## Confirmed decisions

- Target computer is not yet installed or configured as a server; there is no existing server deployment to migrate.
- Hardware budget: 8 GiB system RAM and a GTX 1070 with 8 GiB VRAM.
- Sleep and suspend must be disabled.
- Hostname is unimportant; generate a random one during USB creation and show it before writing the USB.
- A full graphical remote desktop is required. Cockpit remains the host administration interface; it does not replace the desktop.
- Use Ubuntu Server 26.04 LTS bare metal, Autoinstall, Ansible, Docker Compose, and the host NVIDIA proprietary driver plus NVIDIA Container Toolkit.
- Use Tailscale on the host, with no public port forwarding. Tailscale SSH is the preferred CLI path; use Tailscale Serve for private web-management addresses where suitable.
- Home Assistant remains on Home Assistant Green and reaches server services over the wired LAN.
- Cockpit is the host GUI; Arcane is the Docker/Compose GUI with Git-backed projects. The repo already documents Arcane; retain it.
- Monitor with Beszel and Uptime Kuma; back up off-server with Restic and Restic Profile; protect committed secrets with SOPS and age.
- Move Better Lectio only after the host foundation and a real backup/restore test are complete.
- The desired style is mostly hands-off appliance operation, with reviewable Git changes and a repeatable rebuild path.

## Bootstrap question timing

| Value | How to obtain it |
|---|---|
| Hostname | Generate during USB creation, display it, and seed the installer with it. |
| Install disk | Show available drives in the target machine's installer and require an explicit selection and confirmation. |
| Linux account | Ask on the target machine's interactive identity screen; never bake the password into the public seed. |
| Wired network | Use the wired LAN and DHCP by default; let the installer detect the link. |
| Wi-Fi SSID/password | Ask only if Wi-Fi is actually needed; do not require these before USB creation. |
| Tailscale login | Ask on the server during first boot; authenticate from a phone or another computer. Store no reusable auth key on the USB. |
| Hardware facts | Collect after install with a local inventory script; do not require manual transcription. |
| BIOS power-restore setting | Ask for a physical BIOS check later if software cannot read it. |
| Backup target and retention | Ask before migrating production data, not before the blank OS installation. |
| SSH key | Use Tailscale SSH initially. Ask for a public key only if ordinary SSH outside Tailscale is later required. |
| Remote desktop method | Start by validating XFCE plus xrdp as the lightweight full-session option; keep access private to the tailnet. |

## Global Constraints

- Require interactive target-disk selection and confirmation on the server. Never silently choose the largest disk or erase an unconfirmed device.
- Generate the hostname during USB creation, print it in the builder output, and include it in the installer seed.
- Prefer wired Ethernet with DHCP. Ask for Wi-Fi credentials only if Wi-Fi is actually needed.
- Run Tailscale enrollment interactively from the server console; do not put a reusable Tailscale key on the USB.
- Collect hardware and network facts on the target machine after installation. Store detailed serial numbers, MAC addresses, local IPs, and inventory reports locally, outside public Git.
- Install a lightweight full desktop and RDP service; expose RDP only through Tailscale or an explicitly chosen trusted LAN.
- Design for 8 GiB system RAM. Measure memory pressure with the desktop and baseline services running before approving additional workloads.
- Disable sleep, suspend, hibernation, and hybrid sleep through managed configuration.
- Keep management services private; do not add public port forwarding.
- Pin software versions and container images. Candidate releases are not compatibility evidence.
- Keep passwords, private keys, age keys, backup credentials, and rendered installer data out of tracked files.
- Do not migrate production data until an off-server backup has passed a restore test.
- Keep the deployment guard in place until the full post-reboot acceptance gate passes.

## Review Focus

- Autoinstall can default to the largest disk for common layouts; verify the target disk is deliberately selected and confirmed on the physical machine.
- Identity and Wi-Fi prompts must not leave passwords in the public repo, USB seed, shell history, or logs.
- A full desktop, Docker, and workloads share only 8 GiB of system RAM; test their combined peak use and check for OOM events.
- RDP must work from the intended remote client through Tailscale while remaining unavailable from the public internet.
- A successful Restic snapshot is insufficient; restore and open representative service data in a temporary directory.

---

## Task 1: Align repository instructions with the actual choices

**Files:**
- Modify: README.md
- Modify: AGENTS.md
- Modify: docs/architecture.md
- Modify: docs/implementation-plan.md
- Modify: docs/hardware-inventory.md
- Modify: docs/security-and-secrets.md
- Modify: docs/operations.md
- Modify: docs/recovery.md
- Modify: ansible/group_vars/all.yml

**Work:**
- Record the confirmed RAM/VRAM, disabled-sleep requirement, generated hostname, full-desktop requirement, no existing server configuration to migrate, wired-LAN path to Home Assistant Green, and the selected management tools.
- Keep Arcane as the Docker/Compose management UI; the supplied project brief and current main-branch docs explicitly select it for Git-backed Compose workflows.
- Remove stale statements that a desktop environment is out of scope. Keep Cockpit for host administration and add a separate full remote desktop requirement.
- Keep the NVIDIA, Restic/Restic Profile, Tailscale host, Beszel, Uptime Kuma, SOPS/age, and Better Lectio ordering from the supplied project brief.
- Do not require a manually completed hardware inventory before USB creation. Mark machine-specific fields as detected locally or prompted at the stage where they are needed.
- Keep disk serials, MAC addresses, private LAN addresses, and inventory reports out of public Git. Retain the ignored local inventory overlay.
- Defer backup destination details until backup configuration, while requiring a tested restore before production migration.
- Keep deployment_ready false; this task updates documentation and defaults only.

**Verification:**
- Search tracked files for stale “no desktop” exclusions; resolve each conflict with the new requirement.
- Confirm Arcane remains the sole Compose manager in the project docs and this plan.
- Confirm no private address, serial, MAC, password, or key was added to public files.
- Run make check.

**Done when:** The repository reflects all user-confirmed requirements and does not ask the user to manually collect facts the machine or installer can obtain.
## Task 2: Make repository validation test useful negative cases

**Files:**
- Modify: Makefile
- Modify: .github/workflows/validate.yml
- Modify: scripts/check-secrets.sh
- Modify: scripts/validate-compose.sh
- Modify: ansible/requirements.yml
- Create as needed: tests/fixtures/ or ansible/tests/

**Work:**
- Keep YAML lint, Ansible lint, shell lint, syntax checks, Compose validation, and secret-marker scanning in pull-request CI.
- Keep the no-Compose case labelled as a skip; fail if a present Compose file is invalid.
- Add tests that placeholder inventory and deployment_ready=false cannot pass deployment preflight.
- Add tests for missing and mismatched install-disk selection after the installer/bootstrap interface is implemented.
- Keep CI independent of the live server and decrypted credentials.

**Verification:**
- Run make check from a clean checkout.
- In isolated temporary fixtures, prove malformed YAML, shell syntax, invalid Compose, and a known secret marker fail their relevant checks; remove the fixtures afterward.
- Confirm CI reports the Compose check as skipped while no stacks exist and as passed only after a real Compose file is validated.

**Done when:** Repository checks detect the failure cases above without requiring a host or real credentials.

## Task 3: Build a USB writer with a generated hostname

**Files:**
- Create: scripts/make-usb.sh
- Create: autoinstall/build.sh
- Create: autoinstall/validate.sh
- Create: autoinstall/user-data.template
- Modify: .gitignore
- Modify: autoinstall/README.md
- Create: tests/autoinstall/

**Work:**
- Run the USB builder on the user's trusted computer. Download or accept the official Ubuntu Server 26.04 ISO and verify its published checksum before modifying it.
- Generate a random, DNS-safe server hostname at build time. Print it prominently, save a plain hostname record alongside the locally generated USB output, and insert that value as the installer's hostname default.
- Show removable storage devices by model and capacity. Require the user to choose the USB device and confirm the exact device before writing; never guess a target.
- Include the provisioning repository/bootstrap files needed for the first local setup. Keep rendered seed data and output in ignored paths.
- Do not ask the user to collect motherboard, BIOS, NIC, disk serial, or RAM information before USB creation; collect those on the target machine.
- Document that the server installation target disk is chosen later on the target computer, separately from the USB device.

**Verification:**
- Verify the ISO hash against Canonical's published checksum.
- Test that the builder refuses a non-removable target, a missing target, and a confirmation string that does not match the selected USB device.
- Test hostname generation for permitted characters and length; verify the printed hostname matches the hostname in the generated seed.
- Ensure output contains no Wi-Fi password, Tailscale key, age private key, or SSH private key.

**Done when:** A verified installer USB is written only after explicit USB-device confirmation, and the generated hostname is shown to the user.

## Task 4: Use Autoinstall screens for the questions that need a person

**Files:**
- Modify: autoinstall/user-data.template
- Modify: autoinstall/validate.sh
- Modify: autoinstall/README.md
- Create: tests/autoinstall/ interactive-flow fixtures

**Work:**
- Use Ubuntu Autoinstall interactive sections for storage, identity, and network so the installer pauses on the target machine for the remaining choices. Canonical's reference documents interactive-sections and identifies storage, identity, and network as sections that can be interactive: https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html
- Keep the generated hostname as the displayed identity default; allow the user to review it at the console without collecting it in advance.
- Make wired Ethernet DHCP the default. If the user chooses wireless, let the target-side network screen request the SSID and password; do not bake those into the committed template.
- Ask the user to choose and confirm the installation disk on the physical machine. Show enough information to distinguish drives; if two candidates are ambiguous, stop and provide a serial/model listing rather than guess.
- Ask for the Linux user and password on the local installer UI. Do not print, log, or commit the password. Test the exact current Subiquity flow to ensure credentials are not embedded in the USB seed.
- Install only the minimal Ubuntu Server base. Install host services, desktop, and GPU software later through Ansible.
- If the current release's UI cannot safely collect a needed value, make the installer abort with a clear instruction; do not silently switch to unattended defaults.

**Verification:**
- Validate the generated Autoinstall document against the actual 26.04 installer schema.
- Test in a VM with one disk and with multiple disks. Verify storage requires an explicit choice and no layout silently selects the largest disk.
- Test wired DHCP and the optional Wi-Fi path on supported hardware; confirm the saved host network config works after reboot.
- Confirm identity prompts use the generated hostname default and accept local credentials without leaving them in tracked or USB seed files.
- Verify the installer reaches a local SSH-capable Ubuntu Server after reboot.

**Done when:** The USB boot flow asks only for installation-time choices and cannot erase a disk by default.

## Task 5: Collect machine facts and run a simple local bootstrap

**Files:**
- Create: scripts/collect-inventory.sh
- Create: scripts/bootstrap-host.sh
- Create: tests/inventory/
- Modify: .gitignore
- Modify: docs/hardware-inventory.md
- Modify: docs/recovery.md

**Interface:**
- Command: sudo /opt/home-server/scripts/bootstrap-host.sh
- Output: /var/lib/home-server-setup/inventory.json and /var/lib/home-server-setup/inventory.md
- The report records detected facts and marks unavailable values as unknown; it never invents a value.

**Work:**
- Copy the repository's bootstrap files to /opt/home-server during installation so the first setup does not depend on cloning Git before network access is working.
- Collect DMI motherboard/model and BIOS version; CPU model; RAM; PCI GPU identity; disk model, serial, capacity and transport; SMART/NVMe health where supported; NIC model, MAC and interface; OS version; active IP routes; DNS; and Secure Boot state where available.
- Mark BIOS power-restore setting as a human check unless reliable firmware reporting is available. Ask the user to confirm the setting and disable sleep/suspend through configuration later.
- Store the detailed report locally with root-only access. Never auto-upload or commit it to public Git.
- Have the bootstrap command show a concise summary and prompt only for missing choices that block the next step. Do not ask for values already detected or confirmed.
- Keep bootstrap safe to rerun: detect completed steps, explain what will change, and do not reinstall or repartition disks.

**Verification:**
- Run collector tests against fixtures with missing DMI data, multiple drives, missing SMART tools, and multiple NICs.
- Confirm serials and MACs appear only in the local report, not in terminal logs copied to Git or public CI.
- Run bootstrap twice; the second run must identify completed steps and avoid duplicate users, keys, services, or configuration.
- Confirm the script does not attempt to write to a disk.

**Done when:** One command on the installed server produces a useful local inventory and asks only for facts that cannot be reliably discovered.

## Task 6: Implement Ansible preflight and base host configuration

**Files:**
- Modify: ansible/playbooks/site.yml
- Modify: ansible/inventory/hosts.yml
- Modify: ansible/group_vars/all.yml
- Create: ansible/roles/preflight/
- Create: ansible/roles/base/
- Create: ansible/roles/storage/
- Create: ansible/roles/access/

**Interfaces:**
- Preflight consumes the local inventory report and an ignored ansible/inventory/hosts.local.yml overlay.
- The site playbook runs read-only preflight before any mutating role.
- deployment_ready stays false until final acceptance.

**Work:**
- Reject the reserved 192.0.2.10 address, REPLACE_WITH_ADMIN_USER, wrong host, unexpected Ubuntu release, unavailable required disk, and absent recovery access.
- Use detected hardware facts; compare with the confirmed 8 GiB RAM and GTX 1070 expectations and stop for review on a mismatch.
- Configure Europe/Copenhagen time, time sync, baseline packages, security update policy, power behavior, and /srv directory structure.
- Disable sleep, suspend, hibernate, and hybrid-sleep targets through managed systemd configuration.
- Do not repartition or format disks in Ansible. Mount additional explicitly selected storage only by reviewed UUID.
- Configure SSH access after local account creation and Tailscale works; keep password-login changes in a separate reviewed operation.
- Keep host-specific addresses and device IDs in the ignored overlay or encrypted local inventory.

**Verification:**
- Run Ansible lint and syntax checks.
- Test valid and invalid fixture inventories; every invalid case must fail before mutation.
- Run the base roles twice on a disposable test system; the second run must make no unexpected changes.
- Confirm sleep and suspend requests are refused after applying the base role.

**Done when:** Ansible safely configures the installed OS and refuses to touch a host that does not match the reviewed local inventory.

## Task 7: Enroll in Tailscale interactively

**Files:**
- Create: ansible/roles/tailscale/
- Modify: scripts/bootstrap-host.sh
- Modify: docs/operations.md
- Modify: docs/recovery.md

**Work:**
- Install Tailscale on the host after base networking is available.
- Start interactive enrollment from the server console. Display the sign-in instructions so the user can authenticate from a phone or another computer.
- Do not store the user's Tailscale password or a reusable auth key on the USB.
- Use the generated hostname as the initial node name. Document how to rename it in the tailnet if desired.
- Keep wired LAN addressing and Tailscale addressing distinct. Home Assistant Green uses the server's LAN address, not a tailnet route.
- Do not harden SSH or firewall rules until tailnet access has been tested.

**Verification:**
- Confirm the server appears in the intended tailnet and reports connected.
- From a separate device on cellular or another off-LAN network, connect to the server over Tailscale.
- Reboot and verify the tailnet connection returns.
- Keep local keyboard/display recovery available until a second remote session succeeds.

**Done when:** Tailnet access is proven after reboot without any reusable Tailscale secret on the USB or in Git.

## Task 8: Configure Docker, Compose, and LAN boundaries

**Files:**
- Create: ansible/roles/docker/
- Create: ansible/templates/daemon.json.j2
- Create: ansible/templates/docker-logrotate.conf.j2
- Create: tests/docker/
- Modify: stacks/README.md

**Work:**
- Install Docker Engine and Compose v2 through the pinned role or a documented equivalent.
- Configure bounded logs, restart behavior, and application storage under /srv/data. Keep Docker image/layer storage rebuildable.
- Create /srv/stacks, /srv/data, /srv/backups, /srv/cache, and /srv/scratch with explicit ownership and permissions.
- Require each Compose service to state its intended exposure: loopback, tailnet, or a specific LAN address. Reject unrestricted management bindings.
- Document Docker's firewall behavior; review host filtering and container port publication together.
- Do not put production credentials in Compose or public environment files.

**Verification:**
- Validate daemon settings before restarting Docker.
- Run a harmless test container and Compose project.
- Inspect listeners and test intended access from LAN, tailnet, and an external network.
- Reboot and confirm Docker, networking, and data mounts recover in the right order.

**Done when:** Docker survives reboot, persistent paths are separate from image layers, and no management service is publicly reachable.

## Task 9: Enable the GTX 1070 and measure the 8 GiB resource budget

**Files:**
- Create: ansible/roles/nvidia/
- Modify: versions.yml
- Modify: docs/version-policy.md
- Modify: scripts/verify-host.sh
- Create: tests/nvidia/

**Work:**
- Check the current Ubuntu kernel, proprietary Pascal driver, NVIDIA Container Toolkit, and test image compatibility before choosing package versions.
- Record a tested tuple: Ubuntu release/kernel, driver, toolkit, and immutable GPU test image.
- Install the proprietary driver in a separate reviewed change. Grant GPU access only to workloads that need it.
- Measure memory with the base OS, remote desktop, management services, and representative workload running. The machine has 8 GiB of system RAM as well as 8 GiB of GPU VRAM; do not assume those resources are interchangeable.
- Record RAM/swap pressure and OOM events. Keep large workloads out of the baseline acceptance until measured.

**Verification:**
- Confirm nvidia-smi identifies the GTX 1070 on the host.
- Run a pinned container that detects the GPU and executes a small CUDA operation.
- Reboot and repeat host and container GPU tests.
- Record idle and representative peak system RAM use with the desktop active; confirm the chosen baseline remains responsive and has no OOM kills.
- Document a rollback to a known-bootable kernel/driver combination.

**Done when:** The GPU tuple works after reboot and the desktop-plus-baseline memory footprint has been measured.

## Task 10: Add secrets only when a service needs them

**Files:**
- Modify: secrets/README.md
- Modify: secrets/.sops.yaml.example
- Modify: docs/security-and-secrets.md
- Modify: docs/recovery.md
- Create: local ignored age-key setup instructions

**Work:**
- Defer SOPS/age setup until encrypted service or backup credentials are actually needed; it is not a prerequisite for writing the first OS USB.
- Generate the age key on a trusted workstation and keep two independent recovery copies outside the server and Git.
- Test encrypt/decrypt/re-encrypt from a second trusted machine before committing encrypted secrets.
- Never put a private key, Restic password, Tailscale reusable auth key, or plaintext Wi-Fi password in public Git.
- Use interactive Tailscale login instead of a reusable auth key.
- If Wi-Fi is entered in the installer, verify it does not appear in the committed template or USB builder output; treat the installed root-only network config as sensitive.

**Verification:**
- Encrypt a harmless fixture, decrypt it on a second machine, and confirm tracked content is ciphertext.
- Confirm private age key and plaintext fixture remain untracked.
- Confirm recovery notes identify which protected copy is needed for each encrypted repository.

**Done when:** Secret handling is tested before any real service/backup credential is committed or deployed.

## Task 11: Deploy Cockpit and Arcane

**Files:**
- Create: ansible/roles/cockpit/
- Create: stacks/arcane/compose.yaml
- Create: stacks/arcane/README.md
- Modify: docs/architecture.md
- Modify: docs/operations.md
- Modify: scripts/verify-host.sh

**Work:**
- Install Cockpit for Ubuntu host administration and Arcane for Docker/Compose operations; validate and pin the already-recorded candidate release and image.
- Keep both tools reachable through the tailnet or a specifically documented trusted LAN. Use Tailscale Serve for private web addresses where it fits.
- Configure Arcane to operate Git-backed Compose projects so Git remains the permanent source of truth.
- Restrict Docker API access with the narrowest compatible socket-proxy policy; document the API permissions Arcane requires.
- Persist application state under /srv/data and keep stack definitions in Git.
- Cockpit and Arcane are administration interfaces; neither is the full graphical remote desktop.

**Verification:**
- Confirm both interfaces load through the tailnet and fail from a public external network.
- Restart Arcane and confirm its configuration and endpoints persist.
- Deploy a harmless Git-backed Compose change, then roll it back from Git.
- Confirm Docker API access is limited to Arcane and required proxy components.

**Done when:** Host and Docker administration work privately, and Compose deployments remain reproducible from Git.
## Task 12: Provide a full remote desktop

**Files:**
- Create: ansible/roles/desktop/
- Modify: docs/architecture.md
- Modify: docs/security-and-secrets.md
- Modify: docs/operations.md
- Modify: docs/recovery.md
- Modify: scripts/verify-host.sh
- Create: tests/desktop/

**Work:**
- Implement a lightweight XFCE desktop and xrdp as the first candidate. xrdp provides graphical Linux desktop login over RDP and recommends xorgxrdp for the Xorg experience: https://github.com/neutrinolabs/xrdp
- Keep the desktop usable over a remote login session even with no physical monitor. Provide a file manager, terminal, and standard desktop settings; do not install a full Ubuntu Desktop package by default.
- Restrict TCP 3389 to the tailnet interface or an explicitly chosen trusted LAN. Do not forward it from the router or expose it publicly. Tailscale documents RDP as a remote-administration use case: https://tailscale.com/docs/solutions/windows-rdp
- Preserve Cockpit and SSH as separate recovery paths.
- Record session behavior: reconnect, resolution resizing, clipboard, logout, reboot, and concurrent local/remote login behavior.
- Measure desktop RAM and CPU use with the 8 GiB system-memory limit.

**Verification:**
- Connect from the intended RDP client over Tailscale and confirm a usable interactive desktop session.
- Test file manager, terminal, clipboard, resize, disconnect/reconnect, and reboot.
- Confirm port 3389 works through Tailscale and is blocked from the public internet.
- Confirm desktop + baseline services do not cause OOM kills and remain usable during a representative container workload.

**Done when:** The user can reach a full graphical session remotely after reboot with no public RDP exposure.

## Task 13: Add monitoring and tested alert transitions

**Files:**
- Create: stacks/beszel/compose.yaml
- Create: stacks/uptime-kuma/compose.yaml
- Create: service READMEs
- Modify: docs/operations.md
- Modify: scripts/verify-host.sh

**Work:**
- Deploy Beszel Hub/agent and Uptime Kuma with pinned images, persistent data, private access, and bounded logs.
- Monitor host, disks, containers, GPU, remote desktop, and the future production service.
- Add alert destinations only after credentials are available through the approved secret flow.
- Keep HA Green outside this server's failure domain; monitor its availability only if it is useful and authorized.

**Verification:**
- Validate Compose files with Docker Compose.
- Confirm Beszel host/container metrics after reboot; claim GPU telemetry only after observing an actual GPU metric.
- Stop a test service, confirm Kuma alert, restore service, and confirm recovery notification.
- Test stale-health and unavailable-host cases.

**Done when:** Monitoring shows current host/service health and produces verified failure and recovery alerts.

## Task 14: Configure off-server backups and prove restore

**Files:**
- Create: ansible/roles/restic/
- Create: host systemd units or a Restic Profile stack after choosing one execution model
- Create: scripts/verify-backup.sh
- Modify: docs/security-and-secrets.md
- Modify: docs/operations.md
- Modify: docs/recovery.md

**Work:**
- Ask for the off-server repository and retention details at this stage, not during initial installation.
- Back up /srv/data and required machine configuration. Exclude caches, scratch, Docker image layers, and reproducible downloads.
- Add application-consistent database exports before snapshotting services that need them.
- Store Restic password and remote credentials in SOPS or root-only local files with separate recovery copies.
- Schedule checks and backups with non-overlapping jobs, bounded logs, and stale/failure alerts.
- Restore into a temporary path; never verify by overwriting live data.

**Verification:**
- Create a snapshot and inspect its file list.
- Run a Restic integrity check.
- Restore one representative service and database into a temporary location and validate with that service's own tooling.
- Simulate unavailable repository/credentials and verify failure is visible in Kuma.
- Confirm stale-backup alert behavior.

**Done when:** A service's data can be restored from an off-server repository, and backup failure is observable.

## Task 15: Deploy the first production workload over the LAN

**Files:**
- Create: stacks/<service>/compose.yaml
- Create: stacks/<service>/README.md
- Modify: docs/operations.md
- Modify: docs/recovery.md
- Modify: scripts/verify-host.sh

**Work:**
- Choose the first production workload and document ports, persistent data, health checks, dependencies, backup, rollback, and resource budget.
- For Better Lectio, keep Home Assistant on Green and have HA reach the service at its wired LAN address.
- Deploy with test/copied data first. Migrate authoritative data only after the Task 14 restore passes.
- Keep services without a working recovery route out of production.

**Verification:**
- Check service access from the LAN and intended remote access over the tailnet.
- Confirm HA Green reaches it directly over the LAN, without a Tailscale route.
- Reboot, check persistence, and restore into a temporary directory.

**Done when:** The first workload has a tested LAN path, a resource profile, rollback, and restore procedure.

## Task 16: Complete acceptance and recovery exercise

**Files:**
- Modify: scripts/verify-host.sh
- Modify: scripts/deploy.sh
- Modify: docs/implementation-plan.md
- Modify: docs/operations.md
- Modify: docs/recovery.md
- Modify: README.md

**Work:**
- Make the full verification profile fail if a required check is unset or skipped.
- Verify Ubuntu, time, storage mounts, LAN/gateway/DNS/internet, Tailscale, Docker/Compose, host/container GPU, XFCE/xrdp, Cockpit, Arcane, Beszel, Kuma, XFCE/xrdp, production services, and backup freshness/integrity.
- Add deployment preflight for the generated host identity, local inventory, non-placeholder inventory, required secrets, clean repo, and Ansible check/diff.
- Reboot with local console recovery available; verify a second remote Tailscale session and RDP session before closing the original path.
- Restore a real snapshot to temporary storage. Rebuild on a spare disk if available and document manual steps.
- Only after all criteria pass, change deployment_ready in a separate reviewed change and remove the scaffold refusal in a separate reviewed change.

**Verification:**
- Run make check and the full host profile.
- Reboot, rerun the full profile, and check for OOM or service failures.
- Restore a real snapshot to a temporary path and validate the content.
- Test that deployment still refuses when any safety gate is false.

**Done when:** The USB and Ansible reproduce the server; full remote desktop, tailnet and LAN paths work after reboot; GPU and services pass acceptance; and restore/rebuild has been exercised.

## Release gates

1. Do not write the installer USB until the ISO checksum passes and the builder confirms the USB device.
2. Do not start installation until the physical machine's storage screen has an explicitly selected and confirmed target drive.
3. Do not assume the hostname: generate it during USB creation, display it, and use that same value during installation and Tailscale enrollment.
4. Do not restrict SSH/firewall until Tailscale and local console recovery work.
5. Do not expose xrdp, Cockpit, Arcane, Beszel, or Kuma to the public internet.
6. Do not approve the desktop/workload stack until combined use fits the 8 GiB RAM budget without OOM kills.
7. Do not migrate production data until off-server restore is proven.
8. Do not remove the deployment guard until the full post-reboot acceptance profile passes.
