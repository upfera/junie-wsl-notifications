#!/usr/bin/env bash
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
junie_dir=${JUNIE_CONFIG_DIR:-${HOME:?}/.junie}
hooks_dir=$junie_dir/hooks
config=$junie_dir/config.json
logo_name='junie-logo.svg'
logo_source=$root/resources/$logo_name
sentinel='~/.junie/hooks/notify-send.sh'
case "${1:-install}" in
  uninstall)
    [ -f "$config" ] && CONFIG="$config" SENTINEL="$sentinel" python3 "$root/scripts/config.py" remove
    rm -f "$hooks_dir/notify-send.sh"
    if command -v powershell.exe >/dev/null 2>&1; then
      powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \
        "Remove-Item -LiteralPath (Join-Path \$env:USERPROFILE '.junie\\$logo_name') -Force -ErrorAction SilentlyContinue" >/dev/null 2>&1 || true
    fi
    rmdir "$hooks_dir" 2>/dev/null || true
    printf '%s\n' 'Junie notifications uninstalled.'
    ;;
  install)
    mkdir -p "$hooks_dir"
    cp "$root/scripts/notify-send.sh" "$hooks_dir/notify-send.sh"
    if command -v powershell.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
      windows_logo_source=$(wslpath -w "$logo_source")
      powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \
        "New-Item -ItemType Directory -Force -Path (Join-Path \$env:USERPROFILE '.junie') | Out-Null; Copy-Item -LiteralPath '$windows_logo_source' -Destination (Join-Path \$env:USERPROFILE '.junie\\$logo_name') -Force" \
        >/dev/null 2>&1 || true
    fi
    chmod +x "$hooks_dir/notify-send.sh"
    if [ -z "${JUNIE_NOTIFY_EVENTS:-}" ] && { exec 3</dev/tty; } 2>/dev/null; then
      events=(PermissionRequest Stop StopFailure)
      all_events=(SessionStart UserPromptSubmit PreToolUse PermissionRequest Stop StopFailure SessionEnd)
      selected() {
        local candidate
        for candidate in "${events[@]}"; do
          [ "$candidate" = "$1" ] && return 0
        done
        return 1
      }
      read_key() {
        local key rest
        IFS= read -u 3 -rsn1 key || return 1
        if [ "$key" = $'\e' ]; then
          IFS= read -u 3 -rsn2 rest || true
          key+="$rest"
        fi
        REPLY=$key
      }
      index=0
      while true; do
        printf '\033[2J\033[H'
        printf '%s\n\n' 'Select notification events (arrows move, Space toggles, Enter continues):'
        for i in "${!all_events[@]}"; do
          event=${all_events[$i]}
          if selected "$event"; then mark='x'; else mark=' '; fi
          if [ "$i" -eq "$index" ]; then cursor='>'; else cursor=' '; fi
          printf '%s [%s] %s\n' "$cursor" "$mark" "$event"
        done
        printf '\n%s\n' 'Use ↑/↓ to move, Space to toggle, Enter to continue.'
        read_key || break
        case "$REPLY" in
          $'\e[A') index=$(( (index + ${#all_events[@]} - 1) % ${#all_events[@]} )) ;;
          $'\e[B') index=$(( (index + 1) % ${#all_events[@]} )) ;;
          ''|$'\n'|$'\r') break ;;
          c|C) break ;;
          ' ') event=${all_events[$index]}
            if selected "$event"; then
              next=()
              for candidate in "${events[@]}"; do
                [ "$candidate" != "$event" ] && next+=("$candidate")
              done
              events=("${next[@]}")
            else
              events+=("$event")
            fi ;;
        esac
      done
      printf '\033[2J\033[H'
      JUNIE_NOTIFY_EVENTS=$(IFS=,; printf '%s' "${events[*]}")
      exec 3<&-
    fi
    JUNIE_NOTIFY_EVENTS="${JUNIE_NOTIFY_EVENTS:-Stop}" CONFIG="$config" SENTINEL="$sentinel" python3 "$root/scripts/config.py" add
    printf '%s\n' 'Junie notifications installed.'
    ;;
  *) printf 'Usage: %s [install|uninstall]\n' "$0" >&2; exit 2 ;;
esac