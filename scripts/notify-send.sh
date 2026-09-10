#!/usr/bin/env bash
set -euo pipefail
verbose=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    test|-) ;;
    --verbose) verbose=true ;;
    *) input=${input:-}"$1" ;;
  esac
  shift
done
if [ -z "${input:-}" ]; then
  input=$(cat)
fi
event=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("hook_event_name", "Junie"))' 2>/dev/null || printf '%s' Junie)
message=$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print((d.get("last_assistant_message") or d.get("reason") or d.get("prompt") or d.get("tool_name") or "Junie activity").replace("\n", " ")[:240])' 2>/dev/null || printf '%s' 'Junie activity')
title="Junie - $event"
host='Unknown'
target=''
cursor=$PPID
while [ "$cursor" -gt 1 ] 2>/dev/null; do
  process=$(ps -o comm= -p "$cursor" 2>/dev/null || true)
  case "$process" in
    idea|idea64|*idea*) host='IntelliJ IDEA'; target=$cursor; break ;;
    wt|WindowsTerminal|*WindowsTerminal*) host='Windows Terminal'; target=$cursor; break ;;
  esac
  next=$(ps -o ppid= -p "$cursor" 2>/dev/null | tr -d ' ')
  [ -n "$next" ] || break
  cursor=$next
done
notifier_aumid='Microsoft.WindowsTerminal_8wekyb3d8bbwe!App'
if [ -n "${JUNIE_NOTIFY_COMMAND:-}" ]; then "$JUNIE_NOTIFY_COMMAND" "$title" "$message"; exit 0; fi
if command -v powershell.exe >/dev/null 2>&1; then
  title_base64=$(printf '%s' "$title" | base64 -w0)
  message_base64=$(printf '%s' "$message" | base64 -w0)
  ps_command="
\$ErrorActionPreference = 'Stop'
\$encoding = [System.Text.Encoding]::UTF8
\$title = [System.Security.SecurityElement]::Escape(\$encoding.GetString([Convert]::FromBase64String('$title_base64')))
\$body = [System.Security.SecurityElement]::Escape(\$encoding.GetString([Convert]::FromBase64String('$message_base64')))
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
\$logoPath = Join-Path \$env:USERPROFILE '.junie\\junie-logo.svg'
\$logo = if (Test-Path -LiteralPath \$logoPath) { \$logoUri = \$logoPath -replace '\\\\', '/'; \"<image placement='appLogoOverride' hint-crop='none' src='file:///\$logoUri' />\" } else { '' }
[xml]\$toastXml = \"<toast><visual><binding template='ToastGeneric'><text>\$title</text><text>\$body</text>\$logo</binding></visual></toast>\"
Write-Output 'Resolved toast XML:'
Write-Output \$toastXml.OuterXml
\$xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xmlDoc.LoadXml(\$toastXml.OuterXml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('$notifier_aumid').Show((New-Object Windows.UI.Notifications.ToastNotification \$xmlDoc))
"
  if [ "$verbose" = true ]; then
    printf '%s\n' '--- Junie notification debug ---'
    printf 'Input JSON: %s\n' "$input"
    printf 'Event: %s\nTitle: %s\nBody: %s\n' "$event" "$title" "$message"
    printf 'Junie PID: %s\nHost: %s\nHost target: %s\nLogo: %%USERPROFILE%%\\.junie\\junie-logo.svg\n' "$$" "$host" "${target:-<none>}"
    printf '%s\n' 'PowerShell command:'
    printf '%s\n' "$ps_command"
    if ! powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ps_command"; then
      printf '%s\n' 'Windows toast delivery failed; using the local notification fallback.' >&2
      if command -v notify-send >/dev/null 2>&1; then notify-send "$title" "$message" || true; else printf '%s: %s\n' "$title" "$message"; fi
    fi
    printf '%s\n' '--- end debug ---'
  else
    if ! powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ps_command" >/dev/null 2>&1; then
      if command -v notify-send >/dev/null 2>&1; then notify-send "$title" "$message" || true; else printf '%s: %s\n' "$title" "$message"; fi
    fi
  fi
  exit 0
fi
if command -v notify-send >/dev/null 2>&1; then notify-send "$title" "$message" || true; else printf '%s: %s\n' "$title" "$message"; fi