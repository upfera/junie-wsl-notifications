#!/usr/bin/env bash
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
export JUNIE_CONFIG_DIR="$HOME/.junie"
export JUNIE_SKIP_WINDOWS_REGISTRATION=true
mkdir -p "$HOME/.junie"
printf '%s\n' '{"settings":{"keep":true}}' > "$HOME/.junie/config.json"
bash "$root/install.sh"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert set(d["hooks"]) == {"Stop"}; assert d["settings"]["keep"]' "$HOME/.junie/config.json"
printf '%s\n' '{"hook_event_name":"Stop","last_assistant_message":"test event"}' | JUNIE_NOTIFY_COMMAND="$(command -v printf)" "$HOME/.junie/hooks/notify-send.sh" >/dev/null
JUNIE_NOTIFY_COMMAND="$(command -v printf)" "$HOME/.junie/hooks/notify-send.sh" test '{"hook_event_name":"SessionEnd","last_assistant_message":"Test przez WSL — żółć ąćęłńóśźż"}' >/dev/null
JUNIE_NOTIFY_COMMAND="$(command -v printf)" "$HOME/.junie/hooks/notify-send.sh" - test '{"hook_event_name":"Stop","last_assistant_message":"dash test"}' >/dev/null
printf '%s\n' '{"hook_event_name":"Stop","last_assistant_message":"stdin test"}' | JUNIE_NOTIFY_COMMAND="$(command -v printf)" "$HOME/.junie/hooks/notify-send.sh" - >/dev/null
bash -n "$HOME/.junie/hooks/notify-send.sh"
bash -n "$root/install.sh" "$root/scripts/install.sh" "$root/scripts/notify-send.sh" "$root/uninstall.sh"
! grep -R --fixed-strings "/home/tomasz" "$root/scripts"
! grep -R --fixed-strings "wsl.exe -l -q" "$root/scripts"
! grep --fixed-strings "src='shell32.dll" "$root/scripts/notify-send.sh"
for forbidden in Shell32.dll SHGetStockIconInfo SHGetImageList SHIL_JUMBO IImageList System.Drawing; do
  ! grep --fixed-strings "$forbidden" "$root/scripts/notify-send.sh"
done
! grep --fixed-strings "hint-crop='circle'" "$root/scripts/notify-send.sh"
! grep -R --fixed-strings 'Junie.CLI' "$root/scripts" "$root/README.md"
notifier_call="CreateToastNotifier('\$notifier_aumid')"
grep --fixed-strings "$notifier_call" "$root/scripts/notify-send.sh"
grep --fixed-strings "notifier_aumid='Microsoft.WindowsTerminal_8wekyb3d8bbwe!App'" "$root/scripts/notify-send.sh"
! grep --fixed-strings 'launch=' "$root/scripts/notify-send.sh"
grep --fixed-strings "appLogoOverride" "$root/scripts/notify-send.sh"
grep --fixed-strings "junie-logo.svg" "$root/scripts/install.sh" "$root/install.sh" "$root/scripts/notify-send.sh"
bash "$root/uninstall.sh"
test ! -e "$HOME/.junie/hooks/notify-send.sh"
printf '%s\n' 'all tests passed'