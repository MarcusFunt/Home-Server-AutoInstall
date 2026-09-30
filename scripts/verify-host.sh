#!/usr/bin/env bash
set -uo pipefail

failures=0
skips=0
checks=0
profile="${VERIFY_PROFILE:-foundation}"

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }
skip() {
  if [[ "$profile" == full ]]; then
    fail "$1 (required in full profile)"
  else
    printf 'SKIP  %s\n' "$1"
    skips=$((skips + 1))
  fi
}

run_check() {
  local label="$1"
  shift
  checks=$((checks + 1))
  if "$@"; then pass "$label"; else fail "$label"; fi
}

optional_check() {
  local label="$1"
  shift
  checks=$((checks + 1))
  if ! command -v "$1" >/dev/null 2>&1; then skip "$label"
  elif "$@"; then pass "$label"
  else fail "$label"
  fi
}

run_check 'Ubuntu Server 26.04' bash -c '. /etc/os-release && [[ "$ID" == ubuntu && "$VERSION_ID" == 26.04 ]]'
run_check 'system clock synchronized' bash -c '[[ "$(timedatectl show -p NTPSynchronized --value)" == yes ]]'
run_check 'Tailscale daemon active' systemctl is-active --quiet tailscaled
run_check 'Tailscale connected' python3 -c 'import json, subprocess, sys; state=json.loads(subprocess.check_output(["tailscale", "status", "--json"]))["BackendState"]; sys.exit(0 if state == "Running" else 1)'
run_check 'Docker daemon active' systemctl is-active --quiet docker
run_check 'Docker Compose v2 available' docker compose version
run_check 'NVIDIA GPU visible on host' nvidia-smi -L

if [[ -n "${GPU_TEST_IMAGE:-}" ]]; then
  optional_check 'NVIDIA GPU visible in pinned container' docker run --rm --gpus all "$GPU_TEST_IMAGE" nvidia-smi -L
else
  skip 'GPU container test (set GPU_TEST_IMAGE to a tested pinned CUDA image)'
fi

for endpoint_var in COCKPIT_URL ARCANE_URL BESZEL_URL UPTIME_KUMA_URL LECTIO_URL DISPLAY_API_URL; do
  if endpoint="$(printenv "$endpoint_var" 2>/dev/null)"; then :; else endpoint=; fi
  if [[ -z "$endpoint" ]]; then
    skip "$endpoint_var endpoint (not configured)"
    continue
  fi
  run_check "$endpoint_var responds" curl --fail --silent --show-error --max-time 8 "$endpoint"
done

if [[ -n "${RESTIC_REPOSITORY:-}" && -n "${RESTIC_PASSWORD_FILE:-}" ]]; then
  optional_check 'Restic repository check' restic check --read-data-subset=1%
else
  skip 'Restic repository check (configure repository and password file)'
fi

printf 'Checks: %d; skipped: %d; failures: %d\n' "$checks" "$skips" "$failures"
if (( failures > 0 )); then exit 1; fi
