import json, os, sys

path = os.environ["CONFIG"]
sentinel = os.environ["SENTINEL"]
try:
    with open(path, encoding="utf-8") as f: data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError): data = {}
hooks = data.setdefault("hooks", {})
all_events = ("SessionStart", "UserPromptSubmit", "PreToolUse", "PermissionRequest", "Stop", "StopFailure", "SessionEnd")
selected = tuple(event for event in os.environ.get("JUNIE_NOTIFY_EVENTS", "Stop").split(",") if event in all_events)
def clean(groups):
    return [g for g in groups if all(h.get("command") != sentinel for h in g.get("hooks", []))]
for event in all_events:
    groups = clean(hooks.get(event, []))
    if sys.argv[1] == "add" and event in selected: groups.append({"hooks": [{"type": "command", "command": sentinel, "async": True}]})
    if groups: hooks[event] = groups
    else: hooks.pop(event, None)
if not hooks: data.pop("hooks", None)
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w", encoding="utf-8") as f: json.dump(data, f, indent=2); f.write("\n")