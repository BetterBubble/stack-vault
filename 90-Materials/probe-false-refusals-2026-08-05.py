#!/usr/bin/env python3
"""Проба ложных отказов из аудита журнала (05.08.2026).

Каждый кейс — РЕАЛЬНАЯ команда из ~/.claude/permission-denied.log с датой отказа.
Задача пробы: выяснить, какие из них ещё воспроизводятся, а какие закрылись прошлыми правками.
Чинить закрытое — худший вид работы: он выглядит как прогресс и вносит новые дыры.
"""
import json, os, subprocess, sys

HOME = os.path.expanduser("~")
GUARD = f"{HOME}/.claude/hooks/guard.sh"

# (метка, дата отказа в журнале, роль, команда, ожидание: allow = это чтение, отказ был ложным)
CASES = [
    ("bash -n по хуку",            "26.07 03:13", "lead",     f"bash -n {HOME}/.claude/hooks/guard.sh"),
    ("sed -n печать реестра",      "26.07 21:09", "lead",     f"sed -n '1,20p' {HOME}/.claude/.role-registry"),
    ("grep с альтернативой",       "26.07 23:02", "lead",     f"grep -nE 'a|ruby' {HOME}/.claude/hooks/guard.sh"),
    ("grep по statusline",         "26.07 23:02", "lead",     f"grep -nE 'touch|node' {HOME}/.claude/hooks/statusline.sh"),
    ("cp хука НАРУЖУ",             "26.07 02:35", "lead",     f"cp {HOME}/.claude/hooks/guard.sh /tmp/cp-probe.sh"),
    ("grep с autonomy open",       "05.08 20:27", "lead",     f"grep -niE 'окно|autonomy.sh open|барьер' {HOME}/stack-vault/40-Debt/tech-debt.md"),
    ("сигнал с текстом",           "31.07 01:11", "director", f"bash {HOME}/.claude/hooks/signal-send.sh director 'Ночь закрыта. Доставка: ветка ушла, PR готов'"),
    ("сигнал со словом rm",        "—",           "director", f"bash {HOME}/.claude/hooks/signal-send.sh lead-qa 'убрал rm -rf из скрипта, проверь'"),
    ("цикл чтения хуков",          "26.07 23:00", "lead",     'for f in post-compact.sh stop-reminder.sh; do head -3 "$HOME/.claude/hooks/$f"; done'),
]

def ask(role, command):
    payload = json.dumps({"session_id": "probe-fp", "cwd": HOME,
                          "hook_event_name": "PreToolUse", "tool_name": "Bash",
                          "tool_input": {"command": command}})
    p = subprocess.run(["bash", GUARD], input=payload, capture_output=True, text=True,
                       env={**os.environ, "AGENT_ROLE": role})
    out = p.stdout.strip()
    if not out:
        return "allow", ""
    try:
        d = json.loads(out)["hookSpecificOutput"]
        return d.get("permissionDecision", "?"), d.get("permissionDecisionReason", "")[:90]
    except Exception:
        return "?", out[:90]

live = 0
for label, date, role, cmd in CASES:
    dec, why = ask(role, cmd)
    mark = "ЖИВОЙ ДЕФЕКТ" if dec == "deny" else "закрыт"
    if dec == "deny":
        live += 1
    print(f"{mark:14} {label:26} (журнал {date})")
    if why:
        print(f"{'':14} причина: {why}")
print(f"\nвсего живых ложных отказов: {live} из {len(CASES)}")
