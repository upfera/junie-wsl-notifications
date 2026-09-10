# Junie WSL notifications

Notifications for Junie CLI hooks running in WSL. The installer preserves unrelated entries in `~/.junie/config.json`, supports repeated installs and provides a matching uninstall command.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/upfera/junie-wsl-notifications/main/install.sh | bash
```

For uninstall, run the same script with `uninstall` or execute `./uninstall.sh` from a checkout. `JUNIE_CONFIG_DIR` can be used for isolated installations and tests.

On Windows, the installer only installs the WSL hook. It does not register Junie CLI, create a Start Menu shortcut, or create an artificial application identity. Toasts use the installed Windows Terminal notification identity as a stable delivery provider. This avoids creating a Junie application while still allowing WinRT toasts to be delivered from WSL.

During an interactive install, `PermissionRequest`, `Stop`, and `StopFailure` are selected by default. Use the arrow keys to move, `Space` to toggle, and `Enter` to continue. When no terminal is available, or for scripted installs, set `JUNIE_NOTIFY_EVENTS` to a comma-separated list of supported events: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `Stop`, `StopFailure`, and `SessionEnd`. Each configured hook is asynchronous.

Set `JUNIE_NOTIFY_COMMAND` to a command accepting title and message arguments to integrate another desktop notification system or test events. Without it, the hook uses Windows toast notifications when `powershell.exe` is available, then `notify-send`, and finally writes the notification to standard output. The hook accepts JSON from standard input or as an argument and limits the displayed message to 240 characters.

When Windows interop is available, the installer copies `resources/junie-logo.svg` to `%USERPROFILE%\\.junie\\junie-logo.svg` in the Windows user profile. Windows toast notifications use this SVG as the `appLogoOverride` image; if the file is unavailable, the toast is sent without the image.

To test an event with JSON from stdin:

```bash
echo '{"hook_event_name":"Stop","last_assistant_message":"Test przez WSL — żółć ąćęłńóśźż"}' | ~/.junie/hooks/notify-send.sh
```

Or pass JSON directly:

```bash
~/.junie/hooks/notify-send.sh test '{"hook_event_name":"Stop","last_assistant_message":"Test"}'
```

To inspect exactly what is sent to Windows, add `--verbose`:

```bash
~/.junie/hooks/notify-send.sh test --verbose '{"hook_event_name":"Stop","last_assistant_message":"Test przez WSL — żółć ąćęłńóśźż"}'
```

Verbose mode also prints the Junie PID, detected host, and host target. Detection walks the WSL process ancestry and falls back to `Unknown` when no supported host is found. Toasts intentionally have no `launch` activation arguments: the Windows Terminal provider must not receive Junie-specific CLI options when a toast is clicked.