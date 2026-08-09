#!/usr/bin/env bash
# Гонка реестра: закрытие окна против регистрации новой роли.
#
# ВАЖНО ПРО PID. Первая версия пробы подавала фиктивные pid (88888/99999) — и «потеря регистрации»
# в 30 случаях из 30 была не гонкой, а КОРРЕКТНОЙ чисткой по живости: оба скрипта законно
# выбрасывают строки мёртвых процессов. Тест мерил не то, что в названии.
# Здесь регистрируем роль на ЖИВОЙ pid (фоновый sleep), поэтому исчезновение строки может
# означать только затирание.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/race2"; N=30
lost=0

sleep 600 &                     # живой процесс на всё время пробы
LIVE=$!
trap 'kill $LIVE 2>/dev/null' EXIT

for i in $(seq 1 $N); do
  rm -rf "$TH"; mkdir -p "$TH/.claude"
  # Строка умирающей сессии — с мёртвым pid, её и должен убрать session-end.
  printf 'staraya\tlead-old\t99999\n' > "$TH/.claude/.role-registry"

  ( HOME="$TH" bash "$HOME_ORIG/.claude/hooks/session-end.sh" <<< '{"session_id":"staraya"}' >/dev/null 2>&1 ) &
  ( HOME="$TH" CLAUDE_CODE_SESSION_ID="novaya" \
      bash "$HOME_ORIG/.claude/hooks/role-register.sh" lead-new "$LIVE" >/dev/null 2>&1 ) &
  wait %2 %3 2>/dev/null || wait

  grep -q "novaya" "$TH/.claude/.role-registry" 2>/dev/null || lost=$((lost+1))
done

echo "потеряно регистраций: $lost из $N"
[ "$lost" -eq 0 ] && echo "ok — лок держит, свежая регистрация не затирается" \
                  || echo "ПРОВАЛ — регистрации теряются в гонке"
rm -rf "$TH"
