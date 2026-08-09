#!/usr/bin/env bash
# Проба валидации адреса роли: флаг и опечатка не проходят, настоящие адреса проходят.
# Реестр подменяем через HOME, чтобы не тронуть живой: тест, пишущий в настоящий реестр, ломает
# адресацию работающих окон — в этом стеке так уже было с кнопками стопа.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/probe-home"; rm -rf "$TH"; mkdir -p "$TH/.claude"
ok=0; bad=0

t() { # ожидание(pass|deny) · адрес · описание
  local want="$1" role="$2" what="$3" got
  if HOME="$TH" CLAUDE_CODE_SESSION_ID="proba-sid" bash "$HOME/.claude/hooks/role-register.sh" "$role" 99999 >/dev/null 2>&1
  then got=pass; else got=deny; fi
  if [ "$got" = "$want" ]; then ok=$((ok+1)); printf '  ok     %-6s %-22s %s\n' "$got" "$role" "$what"
  else bad=$((bad+1)); printf '  ПРОВАЛ ждали %s, вышло %s — %-18s %s\n' "$want" "$got" "$role" "$what"; fi
}

echo "── флаги и мусор не проходят ──"
t deny "--whoami"        "реальный случай 05.08: два сигнала в мёртвый ящик"
t deny "-v"              "короткий флаг"
t deny "--help"          "длинный флаг"
t deny "lead"            "без направления — канал был бы общим"
t deny "qa"              "направление без префикса lead-"
t deny "Директор"        "кириллица (отсекается прежней проверкой)"

echo "── настоящие адреса проходят ──"
t pass "director"        "дирижёр"
t pass "stack"           "контур стека"
t pass "planner"         "планировщик"
t pass "controller"      "контролёр"
t pass "lead-qa"         "лид направления"
t pass "lead-iva-write-lane" "лид с составным направлением"

echo
if [ "$bad" -eq 0 ]; then echo "ИТОГ: $ok ok, провалов нет"; else echo "ИТОГ: $ok ok, ПРОВАЛОВ $bad"; exit 1; fi
rm -rf "$TH"
