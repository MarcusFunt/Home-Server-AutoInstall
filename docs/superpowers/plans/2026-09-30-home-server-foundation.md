# Home Server Laptop-Prepared USB and Implementation Plan

> **For agentic workers:** Use the executing-plans workflow and complete one task at a time. Keep each task reviewable; do not deploy until its gates are satisfied.

**Goal:** Install and configure the GTX 1070 computer as a rebuildable home server with a full remote desktop, reliable tailnet administration, local LAN integration, monitored container services, and tested off-server recovery.

**Architecture:** A guided builder runs on the laptop before flashing. It collects the few choices and credentials that cannot be discovered, generates a random hostname, verifies the official Ubuntu image, and puts a complete Autoinstall seed plus first-boot provisioning bundle on one USB. The server then installs and configures itself without setup questions: wired DHCP is the default, a guarded disk rule proceeds only when the target is unambiguous, and a one-time Tailscale enrollment credential brings up remote access. First boot silently records detectable hardware facts and runs the bundled Ansible configuration. Any unsafe or ambiguous condition stops before destructive changes and reports the reason.

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

## Laptop setup wizard

The laptop builder owns all choices that can be made before the server boots. Keep the normal path short by preselecting project defaults and asking only for values the laptop cannot safely infer.

| Value | Laptop builder behavior |
|---|---|
| Hostname | Generate a random, DNS-safe hostname; show it in the final summary and include it in the seed. |
| Install target | Default to a guarded “only internal system disk” policy, with an explicit erase confirmation during USB creation. Allow an exact stable device ID only when already known. At boot, continue only when exactly one eligible disk matches; otherwise halt before partitioning. |
| Linux account | Ask for the administrator username and password on the laptop. Generate the installer password hash locally; never log or commit the plaintext password. The account password is also needed for xrdp login. |
| Network | Wired Ethernet with DHCP is the default. Ask for SSID/password on the laptop only if Wi-Fi is selected; do not ask on the server. |
| Tailscale | Accept a one-off, time-limited, pre-approved tagged auth key, or mint one through a suitably restricted OAuth client if already configured. Use a persistent, non-ephemeral node identity; the one-off enrollment key is consumed during provisioning. |
| SSH | Optionally import a public key from the laptop. Never copy a private key. Tailscale SSH remains the alternate CLI path. |
| Locale/timezone | Default to the user's known locale and Europe/Copenhagen; expose these as optional wizard fields. |
| USB device | List removable drives and require exact target confirmation before writing. |
| Service profile | For every service enabled in the build profile, ask for its required choices and credentials on the laptop before writing USB. Keep services with unmet backup/restore prerequisites disabled; never defer their setup prompts to the server. |

Machine facts that only exist on the target—BIOS, CPU, RAM, GPU, disk inventory, NICs, routes, and Secure Boot—are detected silently on first boot. They are not missing configuration questions. Firmware settings that cannot be queried are reported as a commissioning item; they do not trigger an installer prompt.

## Global Constraints

- Prepare the complete base-host configuration on the laptop before flashing. The normal server flow has no identity, network, Tailscale, or provisioning questions.
- Use one guided USB builder: verify the Ubuntu image, collect a compact set of laptop-side choices, generate a random hostname, render the installer and provisioning payload, and write one USB after explicit USB-device confirmation.
- Never silently choose the largest disk. Use an exact stable disk ID if supplied; otherwise proceed only if exactly one eligible internal target exists and the user explicitly approved the single-target erase policy on the laptop. If zero or multiple targets match, stop before partitioning.
- Default to wired Ethernet with DHCP. Wi-Fi credentials are optional, entered on the laptop, excluded from Git/logs, and included only in the private USB payload.
- Use a one-off, time-limited Tailscale auth key for unattended enrollment. Do not put a reusable key or Tailscale account password on the USB. Do not use an ephemeral node key for this always-on server.
- Treat the generated USB as a sensitive, short-lived provisioning artifact. Keep it physically controlled; do not commit rendered files, passwords, Wi-Fi credentials, or auth keys. Delete transient copies from the laptop and installed host after use.
- Automatically collect target hardware/network facts on first boot and store detailed serials, MACs, and local IPs in a root-only local report; do not auto-upload or commit it.
- Install a standard lightweight desktop from existing Ubuntu packages and use upstream xrdp/xorgxrdp. Do not design or implement a custom desktop environment.
- Keep management services private; do not add public port forwarding.
- Design for 8 GiB system RAM. Measure memory pressure with the desktop and baseline services running before approving additional workloads.
- Disable sleep, suspend, hibernation, and hybrid sleep through managed configuration.
- Reuse maintained upstream packages, roles, and projects where they fit. Write only the integration/configuration glue specific to this server.
- Pin software versions and container images. Candidate releases are not compatibility evidence.
- Do not migrate production data until an off-server backup has passed a restore test.
- Keep the deployment guard in place until the full post-reboot acceptance gate passes.

## Review Focus

- A fully automated Autoinstall seed must be tested against the actual Ubuntu 26.04 installer; no server-side prompt should appear on the success path.
- The disk guard must fail closed before any partition or format operation when the target is missing or ambiguous.
- The USB necessarily carries limited bootstrap material. Keep the Tailscale key one-off and time-limited, keep plaintext passwords out of it by storing only the generated hash, and include Wi-Fi secrets only if Wi-Fi was selected.
- The first-boot process must remove transient enrollment material and must not expose secrets in logs, Ansible output, or the inventory report.
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
- Record the confirmed RAM/VRAM, disabled-sleep requirement, generated hostname, full-desktop requirement, laptop-prepared unattended setup, no existing server configuration to migrate, wired-LAN path to Home Assistant Green, and selected management tools.
- Keep Arcane as the Docker/Compose management UI; the supplied project brief and current main-branch docs explicitly select it for Git-backed Compose workflows.
- Clarify that “desktop environment out of scope” means no custom desktop environment. Use standard XFCE packages plus upstream xrdp/xorgxrdp (or another proven package-based stack) and keep Cockpit for host administration.
- Keep the NVIDIA, Restic/Restic Profile, Tailscale host, Beszel, Uptime Kuma, SOPS/age, and Better Lectio ordering from the supplied project brief.
- Do not require a manually completed hardware inventory before USB creation. Detect target-specific facts silently at first boot; ask only non-detectable configuration questions in the laptop builder.
- Keep disk serials, MAC addresses, private LAN addresses, and inventory reports out of public Git. Retain the ignored local inventory overlay.
- Defer backup destination details until backup configuration; they are outside the base USB wizard, and a tested restore remains mandatory before production migration.
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
- Add tests proving the installer proceeds only for a unique approved disk match and halts before writes for zero or multiple matches.
- Keep CI independent of the live server and decrypted credentials.

**Verification:**
- Run make check from a clean checkout.
- In isolated temporary fixtures, prove malformed YAML, shell syntax, invalid Compose, and a known secret marker fail their relevant checks; remove the fixtures afterward.
- Confirm CI reports the Compose check as skipped while no stacks exist and as passed only after a real Compose file is validated.

**Done when:** Repository checks detect the failure cases above without requiring a host or real credentials.

## Task 3: Build a guided laptop configuration and USB writer

**Files:**
- Create: scripts/make-usb.ps1 or an equivalent one-command launcher for the laptop OS in use
- Create: autoinstall/build.sh or a cross-platform renderer called by the launcher
- Create: autoinstall/validate.sh
- Create: autoinstall/user-data.template
- Create: scripts/first-boot/
- Modify: .gitignore
- Modify: autoinstall/README.md
- Create: tests/autoinstall/

**Work:**
- Provide one guided laptop flow: check dependencies, download or select the official Ubuntu Server 26.04 ISO, verify its published checksum, choose the host/service profile, ask for every missing value required by that profile, render the install seed and first-boot configuration, and write one USB.
- Keep the ordinary path fast: hostname is generated; timezone is prefilled; wired Ethernet/DHCP and the guarded single-internal-disk policy are defaults. Ask for an admin username/password and only the inputs required by selected optional modules. Do not emit a partial profile that will prompt on the server.
- Include all repository configuration and pinned Ansible dependencies required by the selected build profile, or a reproducible way to obtain them without Git credentials. Online package/dependency downloads may occur during first boot over Ethernet; configuration values themselves are prepared on the laptop.
- Use an existing, maintained USB/image-writing tool or library where practical. Do not implement an ISO filesystem writer or installer from scratch without a demonstrated need.
- Generate and display a random, DNS-safe hostname; save a local build receipt with the hostname, ISO checksum, selected disk policy, and USB target, but no secrets.
- Ask for the USB device by model/capacity and require exact confirmation before overwrite; never guess the removable target.
- Default disk policy: user confirms on the laptop that the sole eligible internal system disk may be erased. At install time, exclude the installer USB and continue only if exactly one eligible target matches. If there are multiple internal drives, the user can disconnect non-target drives before boot or rebuild with an exact stable ID; the installer must otherwise halt without partitioning.
- Generate the account password hash locally. If Wi-Fi is selected, place its credentials only in the private rendered payload. If a Tailscale auth key is supplied, place a one-off time-limited key in a separate root-only USB sidecar file, not in Autoinstall YAML or commands that may be logged. Never include a reusable auth key, API token, age private key, or SSH private key.
- Keep generated images, rendered seeds, provisioning secrets, and logs out of Git. Decrypt selected SOPS files on the laptop immediately before rendering the private USB payload; never copy the age private key to the USB. Tell the user to retain physical control of the USB until the single-use enrollment key has been consumed.

**Verification:**
- Verify the ISO hash against Canonical's published checksum.
- Test refusal for a missing/non-removable/ambiguous USB target and for a confirmation string that does not match the selected USB.
- Test hostname generation and prove the displayed hostname matches the seed, first-boot configuration, and build receipt.
- Test each wizard default and optional branch without printing passwords or tokens to the terminal or logs.
- Confirm the artifact contains only the password hash, and only contains Wi-Fi credentials when Wi-Fi was selected.
- Inspect the completed USB payload and prove no SSH private key, age key, Tailscale reusable key, or OAuth secret is present.
- Test that a generated USB can boot in a VM and reaches unattended installation with no human input beyond selecting the boot device if the firmware requires it.

**Done when:** One laptop wizard produces a verified, self-contained provisioning USB, prints the generated hostname and a concise summary, and never writes to an unconfirmed USB target.

## Task 4: Make Ubuntu Autoinstall fully unattended on the success path

**Files:**
- Modify: autoinstall/user-data.template
- Modify: autoinstall/validate.sh
- Modify: autoinstall/README.md
- Create: tests/autoinstall/unattended-flow fixtures

**Work:**
- Use a fully populated Ubuntu Autoinstall configuration with no interactive sections. The laptop builder supplies identity, network defaults, storage policy, packages, and first-boot payload.
- Use wired Ethernet DHCP by default. If Wi-Fi was selected in the laptop wizard, configure it from the private seed; do not prompt on the server.
- Create the administrator account from the laptop-provided username and generated password hash. Install OpenSSH; add only the optional public key supplied on the laptop. Disable SSH password login after Tailscale is confirmed, not during initial bootstrap.
- Enforce the approved storage policy before any destructive storage action. If a stable device ID is configured, require exactly one match. Otherwise require exactly one eligible internal non-removable drive after excluding the installer USB. On mismatch, stop before partitioning and write a clear error to the local console/log.
- Install only the minimal Ubuntu Server base during Autoinstall. Install the desktop, xrdp, host services, and GPU software through the bundled Ansible configuration.
- Use the documented Autoinstall NoCloud/seed mechanism or a maintained image-preparation tool to keep the official ISO checksum verifiable and the seed reproducible. Select the simplest approach that supports a single USB and test it on the actual 26.04 installer.
- Never silently convert an unattended failure into automatic largest-disk selection or an unexpected interactive installer screen.

**Verification:**
- Validate the rendered Autoinstall document against the actual 26.04 installer schema.
- Test in a VM with one eligible disk, multiple eligible disks, an installer USB plus one target, and no eligible target. Verify only the unique approved target proceeds.
- Confirm identity and network configuration apply without input and the generated hostname survives reboot.
- Test wired DHCP and, if supported, the optional Wi-Fi seed path; verify credentials do not appear in logs or the inventory report.
- Verify installation reaches a local SSH-capable Ubuntu Server after reboot, then starts first-boot provisioning automatically.

**Done when:** The USB completes a safe install without setup questions when preflight conditions match, and halts before disk writes when they do not.

## Task 5: Collect machine facts and provision automatically on first boot

**Files:**
- Create: scripts/collect-inventory.sh
- Create: scripts/first-boot-provision.sh
- Create: systemd/first-boot-provision.service
- Create: tests/inventory/
- Modify: .gitignore
- Modify: docs/hardware-inventory.md
- Modify: docs/recovery.md

**Interface:**
- Trigger: one-shot systemd service installed by Autoinstall; no command needs to be typed on the server.
- Output: /var/lib/home-server-setup/inventory.json, inventory.md, and a sanitized provisioning result.
- The report records detected facts and marks unavailable values as unknown; it never invents a value.

**Work:**
- Copy the first-boot bundle and all selected, pre-rendered configuration from the USB into /opt/home-server during installation. Keep the Tailscale key in a separate root-only sidecar, not in the saved Autoinstall file. Apply only roles allowed by the bootstrap/production safety gates.
- Start automatically after networking is online. Collect DMI motherboard/model and BIOS version; CPU; RAM; PCI GPU identity; disk model, serial, capacity and transport; SMART/NVMe health where supported; NIC model/MAC/interface; OS version; routes; DNS; and Secure Boot state where available.
- Run a narrow first-install bootstrap playbook locally using the laptop-generated host variables. This path configures only the base host and does not bypass the separate guard on ordinary production deployments. Do not prompt for values on the server; do not repartition or format disks from this service.
- Read the short-lived Tailscale enrollment secret from a separate root-only USB sidecar file, enroll the host, then remove the staged copy and redact task output. Do not place the key in cloud-init or installer logs. Preserve the resulting node identity so the always-on device reconnects after reboot.
- Disable sleep/suspend and install the selected standard desktop/RDP packages as part of the automated host configuration.
- Store detailed inventory locally with root-only permissions. Do not auto-upload or commit serials, MACs, or IPs.
- After network setup, inspect installer/cloud-init caches and logs for rendered secrets; restrict or remove temporary seed copies when safe, while retaining only the root-only network configuration needed for connectivity.
- If first-boot configuration fails, stop dependent steps and leave a clear, sanitized status on the console and local log. Never fall back to asking setup questions.

**Verification:**
- Test collector fixtures with missing DMI data, multiple drives, missing SMART tools, and multiple NICs.
- Confirm private values and inventory serials/MACs do not appear in provisioning logs, Git, or CI.
- Install from USB in a VM, verify first-boot provisioning runs automatically, and reboot twice to prove it does not duplicate state.
- Prove no bootstrap step writes to a disk after the OS install.
- Confirm the enrollment secret is absent from installed files after successful Tailscale enrollment.

**Done when:** A first boot automatically records inventory and configures the host from the laptop-prepared bundle with no interactive setup command.

## Task 6: Implement Ansible preflight and base host configuration

**Files:**
- Modify: ansible/playbooks/site.yml
- Modify: ansible/inventory/hosts.yml
- Modify: ansible/group_vars/all.yml
- Create: ansible/playbooks/bootstrap.yml
- Create: ansible/roles/preflight/
- Create: ansible/roles/base/
- Create: ansible/roles/storage/
- Create: ansible/roles/access/

**Interfaces:**
- The bootstrap playbook consumes the local inventory report and laptop-generated host variables from the private USB payload; any host-specific overlay is rendered locally and remains ignored/untracked.
- The bootstrap path runs read-only preflight before mutating base-host roles. It does not deploy production Compose stacks.
- The ordinary deploy command remains blocked and deployment_ready stays false until final acceptance.

**Work:**
- Reject the reserved 192.0.2.10 address, placeholder account/host values, unexpected Ubuntu release, missing disk-policy attestation, and absent recovery access.
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

## Task 7: Enroll in Tailscale automatically from the laptop-prepared bundle

**Files:**
- Create: ansible/roles/tailscale/
- Modify: scripts/first-boot-provision.sh
- Modify: docs/operations.md
- Modify: docs/recovery.md

**Work:**
- Install Tailscale on the host after base networking is available.
- Before flashing, provide a one-off, time-limited, pre-approved tagged auth key in the laptop wizard. Support a suitably restricted OAuth client as an optional way to mint that one-off key. Keep account login, OAuth credentials, and reusable keys off the USB.
- Use a persistent, non-ephemeral node identity so this always-on server remains registered after reboot. Do not confuse a one-off auth key with an ephemeral node.
- Enroll unattended, using the generated hostname as the initial node name. Tailscale's one-off key is revoked after use; remove its staged copy from the installed host and redact it from logs.
- If the existing tailnet policy cannot issue the required key, stop the USB build with a clear laptop-side instruction rather than leaving a first-boot prompt on the server.
- Keep wired LAN addressing and Tailscale addressing distinct. Home Assistant Green uses the server's LAN address, not a tailnet route.
- Do not harden SSH or firewall rules until tailnet access has been tested.

**Verification:**
- Confirm the server appears in the intended tailnet with the requested tag and reports connected.
- From a separate device on cellular or another off-LAN network, connect to the server over Tailscale.
- Reboot and verify the node reconnects with its persistent identity.
- Confirm the one-off auth key is unusable after enrollment and no copy remains in installed files or logs.

**Done when:** Tailnet access is provisioned without interaction at the server, remains available after reboot, and no reusable Tailscale secret is stored on the USB.

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

## Task 10: Protect laptop-generated secrets and the provisioning USB

**Files:**
- Modify: secrets/README.md
- Modify: secrets/.sops.yaml.example
- Modify: docs/security-and-secrets.md
- Modify: docs/recovery.md
- Create: local ignored age-key setup instructions

**Work:**
- Keep persistent application/backup secrets out of the base-only profile. When a service is selected for installation, decrypt its SOPS values on the laptop and render them into the private USB payload; never ask for them at the server.
- Never place passwords, Wi-Fi credentials, OAuth secrets, private keys, or rendered user-data in Git or builder logs.
- Store only a locally generated password hash in Autoinstall. Wi-Fi credentials appear in the USB payload only if Wi-Fi is selected and are written root-only on the installed host.
- Treat the USB as a secret-bearing device while it contains a Tailscale one-off auth key. Keep physical control until the key is consumed; do not rely on flash deletion as the sole revocation mechanism.
- Prefer one-off Tailscale auth keys. If a laptop-side OAuth client is used to mint one, store its restricted credential only in the laptop's approved secret store and never copy it to the USB.
- Delete transient plaintext files and local staging copies after the USB is built. Keep the generated, secret-bearing provisioning USB under physical control and separate from the public repo.
- Generate the age key on a trusted workstation and keep two independent recovery copies outside the server and Git when encrypted application secrets are later introduced.
- Test encrypt/decrypt/re-encrypt from a second trusted machine before committing encrypted service secrets.

**Verification:**
- Scan tracked files, builder logs, and generated output summary for secret markers and accidental plaintext.
- Confirm private age key, Wi-Fi secret, Tailscale key, password, and rendered user-data remain untracked.
- Confirm only the selected optional secrets appear in the private USB payload; verify post-install cleanup and Tailscale key revocation.
- Confirm recovery notes identify which protected copy is needed for each encrypted repository.

**Done when:** The laptop build protects transient provisioning secrets, the installed host retains only necessary credentials, and future persistent secrets have a tested SOPS/age recovery path.

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
- Reuse the standard XFCE desktop packages available from Ubuntu and upstream xrdp with xorgxrdp for the remote Xorg session: https://github.com/neutrinolabs/xrdp. This task installs and configures existing software; it does not build a desktop environment.
- Keep the desktop usable over a remote login session even with no physical monitor. Install the normal file manager, terminal, and settings applications from distribution packages; avoid installing the full Ubuntu Desktop meta-package unless testing shows it is necessary.
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
- Verify Ubuntu, time, storage mounts, LAN/gateway/DNS/internet, Tailscale, Docker/Compose, host/container GPU, the reused XFCE/xrdp stack, Cockpit, Arcane, Beszel, Kuma, production services, and backup freshness/integrity.
- Add deployment preflight for the generated host identity, local inventory, laptop-generated configuration receipt, non-placeholder values, required secrets, clean repo, and Ansible check/diff.
- Reboot with local console recovery available; verify a second remote Tailscale session and RDP session before closing the original path.
- Restore a real snapshot to temporary storage. Rebuild on a spare disk if available and document manual steps.
- Only after all criteria pass, change deployment_ready in a separate reviewed change and remove the refusal from the ordinary production deploy path. The restricted first-install bootstrap remains available for rebuilding a host.

**Verification:**
- Run make check and the full host profile.
- Reboot, rerun the full profile, and check for OOM or service failures.
- Restore a real snapshot to a temporary path and validate the content.
- Test that deployment still refuses when any safety gate is false.

**Done when:** The USB and Ansible reproduce the server; full remote desktop, tailnet and LAN paths work after reboot; GPU and services pass acceptance; and restore/rebuild has been exercised.

## Release gates

1. Do not write the installer USB until the ISO checksum passes, the USB device is confirmed, and the laptop wizard records explicit approval for the target-disk policy.
2. Do not partition if the exact configured disk ID does not match once, or if the guarded single-internal-disk policy finds anything other than exactly one eligible target; stop before writes without prompting on the server.
3. Do not assume the hostname: generate it during USB creation, display it, and use that same value during installation, first-boot provisioning, and Tailscale enrollment.
4. Do not restrict SSH/firewall until Tailscale and local console recovery work.
5. Do not expose xrdp, Cockpit, Arcane, Beszel, or Kuma to the public internet.
6. Do not approve the desktop/workload stack until combined use fits the 8 GiB RAM budget without OOM kills.
7. Do not migrate production data until off-server restore is proven.
8. Do not remove the deployment guard until the full post-reboot acceptance profile passes.
9. The success path must need no server-side configuration answers: select the USB from the firmware one-time boot menu if needed, then let installation/provisioning finish. Do not change persistent boot order to prefer USB; verify reboot returns to the installed system. Remove the USB after setup is confirmed.
10. Use existing Ubuntu desktop packages and upstream xrdp/xorgxrdp; do not create a custom desktop environment.
