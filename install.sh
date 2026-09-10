#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ -f "$ROOT_DIR/scripts/install.sh" ]; then
  exec bash "$ROOT_DIR/scripts/install.sh" "$@"
fi
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
base_url="https://raw.githubusercontent.com/upfera/junie-wsl-notifications/main"
for file in scripts/install.sh scripts/config.py scripts/notify-send.sh scripts/activate-host.ps1 resources/junie-logo.svg; do
  mkdir -p "$tmp_dir/$(dirname "$file")"
  curl -fsSL "$base_url/$file" -o "$tmp_dir/$file"
done
chmod +x "$tmp_dir/scripts/install.sh" "$tmp_dir/scripts/notify-send.sh"
exec bash "$tmp_dir/scripts/install.sh" "$@"