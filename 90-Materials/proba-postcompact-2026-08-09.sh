#!/usr/bin/env bash
# Проба: после сжатия контекста роль стека получает ВЕРНЫЙ путь к состоянию и без ложного
# заверения, будто его кто-то переписал перед сжатием.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/pchome"; rm -rf "$TH"; mkdir -p "$TH/.claude"
H="$HOME/.claude/hooks/post-compact.sh"

# 1) событие сжатия — ставит флаг
printf '{"session_id":"pcprobe","hook_event_name":"PostCompact","trigger":"auto"}' \
  | env HOME="$TH" AGENT_ROLE=stack AGENT_VAULT="$HOME/stack-vault" bash "$H" >/dev/null 2>&1
# 2) следующий промпт — текст доезжает до модели
out="$(printf '{"session_id":"pcprobe","hook_event_name":"UserPromptSubmit"}' \
  | env HOME="$TH" AGENT_ROLE=stack AGENT_VAULT="$HOME/stack-vault" bash "$H" 2>/dev/null)"

echo "── что уедет в контекст (роль stack) ──"
printf '%s\n' "$out" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(" ", d.get("hookSpecificOutput",{}).get("additionalContext","(пусто)")[:400])
except Exception as e:
    print("  не разобрано:", e)'

bad=0
printf '%s' "$out" | grep -q "30-Sessions/stack-state.md" && echo "  ok     путь контура стека верный" \
  || { echo "  ПРОВАЛ путь ведёт не туда"; bad=$((bad+1)); }
printf '%s' "$out" | grep -q "переписал хук PreCompact" && { echo "  ПРОВАЛ осталось ложное заверение"; bad=$((bad+1)); } \
  || echo "  ok     ложного заверения нет"
printf '%s' "$out" | grep -q "Роль окна не определена" && { echo "  ПРОВАЛ роль stack не опознана"; bad=$((bad+1)); } \
  || echo "  ok     роль stack опознана"

echo "── контроль: рабочая роль получает свой путь ──"
printf '{"session_id":"pcprobe2","hook_event_name":"PostCompact","trigger":"auto"}' \
  | env HOME="$TH" AGENT_ROLE=director AGENT_VAULT="$HOME/tacticum-vault" bash "$H" >/dev/null 2>&1
out2="$(printf '{"session_id":"pcprobe2","hook_event_name":"UserPromptSubmit"}' \
  | env HOME="$TH" AGENT_ROLE=director AGENT_VAULT="$HOME/tacticum-vault" bash "$H" 2>/dev/null)"
printf '%s' "$out2" | grep -q "01-Sessions/session-state.md" && echo "  ok     путь рабочего контура сохранён" \
  || { echo "  ПРОВАЛ путь рабочего контура сломан"; bad=$((bad+1)); }

rm -rf "$TH"
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
