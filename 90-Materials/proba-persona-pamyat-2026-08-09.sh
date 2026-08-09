#!/usr/bin/env bash
# Проба: доктор ловит персону, утверждающую о пустой памяти, когда память не пуста.
# Живые файлы не трогаем — подменяем HOME целиком.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/pershome"; rm -rf "$TH"; mkdir -p "$TH/.claude/agents" "$TH/.claude/agent-memory/verifier"

check() { # описание · ожидание(bad|ok)
  local what="$1" want="$2" out got
  out="$(cd "$TH" && for ag in verifier; do
    agf="$TH/.claude/agents/$ag.md"; memd="$TH/.claude/agent-memory/$ag"
    if grep -qE "[Пп]ока (она )?пуст" "$agf" 2>/dev/null; then
      cnt=0; [ -d "$memd" ] && cnt="$(ls -1 "$memd" 2>/dev/null | wc -l | tr -d ' ')"
      [ "${cnt:-0}" -gt 0 ] && echo "bad" || echo "ok"
    else echo "ok"; fi
  done)"
  got="$out"
  if [ "$got" = "$want" ]; then printf '  ok     %-4s %s\n' "$got" "$what"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$want" "$got" "$what"; fi
}

printf 'память пока пуста, начинай с нуля\n' > "$TH/.claude/agents/verifier.md"
printf 'заметка\n' > "$TH/.claude/agent-memory/verifier/n1.md"
check "утверждение о пустоте при непустой памяти" bad

rm -f "$TH/.claude/agent-memory/verifier/n1.md"
check "то же утверждение при реально пустой памяти" ok

printf 'память подставляется автоматически, прочитай её\n' > "$TH/.claude/agents/verifier.md"
printf 'заметка\n' > "$TH/.claude/agent-memory/verifier/n1.md"
check "персона описывает механизм, а не состояние" ok

rm -rf "$TH"
