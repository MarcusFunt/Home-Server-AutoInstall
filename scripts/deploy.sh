#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' 'DEPLOY BLOCKED: this repository is still a scaffold.' >&2
printf '%s\n' 'Implement and review Ansible roles, inventory, secrets, deployment preflight, and acceptance checks first.' >&2
printf '%s\n' 'See docs/implementation-plan.md. Remove this guard only in a separately reviewed change.' >&2
exit 78
