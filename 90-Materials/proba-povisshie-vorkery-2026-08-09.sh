#!/usr/bin/env bash
# Проба: доктор ловит настоящего повисшего воркера и молчит на закрытых парах,
# включая пары с обрезанным agent_id (реальный случай журнала 09.08).
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
V="$S/wvault"; rm -rf "$V"; mkdir -p "$V/00-Board"
OLD="$(date -v-90M '+%Y-%m-%d %H:%M' 2>/dev/null || date -d '90 minutes ago' '+%Y-%m-%d %H:%M')"

case_() { # $1 — содержимое журнала, $2 — что ожидаем (hung|clean), $3 — описание
  printf '%s' "$1" > "$V/00-Board/_workers.md"
  out="$(AGENT_VAULT="$V" bash "$HOME/.claude/hooks/stack-doctor.sh" 2>&1 | grep -c "не вернулись")"
  got=clean; [ "$out" -gt 0 ] && got=hung
  if [ "$got" = "$2" ]; then printf '  ok     %-6s %s\n' "$got" "$3"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$2" "$got" "$3"; fi
}

case_ "- $OLD START worker-a spawner=stack agent=aworker-a-full sess=s1 ·
" hung "настоящий повисший (START без STOP)"

case_ "- $OLD START worker-b spawner=stack agent=aworker-b-full sess=s1 ·
- $OLD STOP  worker-b spawner=stack agent=aworker-b-full sess=s1 · 5м · ok
" clean "обычная закрытая пара"

case_ "- $OLD START worker-c spawner=stack agent=aworker-c sess=s1 ·
- $OLD STOP  worker-c spawner=stack agent=aworker-c-polnyj-id-2c00700f sess=s1 · 5м · ok
" clean "пара с ОБРЕЗАННЫМ id в START (случай 09.08)"

case_ "- $OLD START worker-d spawner=stack agent=aworker-d-full sess=s1 ·
- $OLD STOP  worker-e spawner=stack agent=aworker-e-full sess=s1 · 5м · ok
" hung "чужой STOP не закрывает висящего"

rm -rf "$V"
