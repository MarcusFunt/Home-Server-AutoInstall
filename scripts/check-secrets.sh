#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '%s\n' 'Secret scan requires a Git worktree.' >&2
  exit 2
fi

if git grep --files-with-matches -I -E 'AGE-SECRET-KEY-1|-----BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}' -- . ':!scripts/check-secrets.sh'; then
  printf '%s\n' 'Potential plaintext secret marker found in tracked files.' >&2
  exit 1
fi

if git ls-files | grep -E '(^|/)\.env$|(^|/)(id_rsa|id_ed25519)$' >/dev/null; then
  printf '%s\n' 'A plaintext environment file or SSH private key is tracked.' >&2
  exit 1
fi

printf '%s\n' 'PASS: no configured plaintext secret markers found.'
