#!/usr/bin/env bash
set -euo pipefail

mapfile -d '' compose_files < <(find stacks -type f \( -name compose.yaml -o -name compose.yml -o -name docker-compose.yaml -o -name docker-compose.yml \) -print0)

if (${#compose_files[@]} -eq 0); then
  printf '%s\n' 'SKIP: no Compose projects exist yet.'
  exit 0
fi

command -v docker >/dev/null 2>&1 || {
  printf '%s\n' 'Docker is required to validate Compose files.' >&2
  exit 2
}

for file in "${compose_files[@]}"; do
  docker compose --file "$file" config --quiet
  printf 'PASS: %s\n' "$file"
done
