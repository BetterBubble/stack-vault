#!/usr/bin/env bash
# Пробы по находкам седьмого круга: тильда-фенс и CRLF в очереди, detached HEAD в авто-коммите.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
bad=0

echo "── очередь решений: тильда-фенс и CRLF ──"
V="$S/k7wq"; rm -rf "$V"; mkdir -p "$V/00-Board"
{ printf -- "---\ntitle: карточка\n---\n\n"
  printf -- "@ЖДЁТ: настоящая развилка · [[карточка]]\n\n"
  printf -- "~~~\n@ЖДЁТ: пример внутри тильда-фенса\n~~~\n"
} > "$V/00-Board/card.md"
printf -- '@ЖДЁТ: развилка из CRLF файла\r\n' > "$V/00-Board/crlf.md"

bash "$HOME/.claude/hooks/waiting-queue.sh" --vault "$V" >/dev/null 2>&1
q="$(awk '/^## Ждёт решения/,/^## Похоже/' "$V/00-Board/_zhdet-resheniya.md")"
printf '%s\n' "$q" | grep '^- ' | sed 's/^/  /'

printf '%s' "$q" | grep -q "настоящая развилка" && echo "  ok     настоящая развилка взята" \
  || { echo "  ПРОВАЛ развилка потеряна"; bad=$((bad+1)); }
printf '%s' "$q" | grep -q "внутри тильда-фенса" && { echo "  ПРОВАЛ пример из ~~~ попал в очередь"; bad=$((bad+1)); } \
  || echo "  ok     тильда-фенс распознан как код"
printf '%s' "$q" | grep -q "развилка из CRLF файла" && echo "  ok     строка из CRLF-файла взята" \
  || { echo "  ПРОВАЛ CRLF-строка потеряна"; bad=$((bad+1)); }
printf '%s' "$q" | grep -q $'\r' && { echo "  ПРОВАЛ возврат каретки уехал в очередь"; bad=$((bad+1)); } \
  || echo "  ok     возврат каретки снят"
rm -rf "$V"

echo "── авто-коммит памяти: detached HEAD не теряет данные молча ──"
PV="$S/k7det"; rm -rf "$PV"; mkdir -p "$PV"
( cd "$PV" && git init -q . && git config user.email p@l && git config user.name p \
  && printf 'a\n' > a.md && git add -A && git commit -q -m init \
  && printf 'b\n' > b.md && git add -A && git commit -q -m second \
  && git checkout -q HEAD~1 ) >/dev/null 2>&1
before=$(git -C "$PV" log --oneline | wc -l | tr -d ' ')
printf 'новое\n' > "$PV/c.md"
STACK_VAULT="$PV" AGENT_VAULT="$PV" bash "$HOME/.claude/hooks/session-end.sh" <<< '{"session_id":"det"}' >/dev/null 2>&1
after=$(git -C "$PV" log --oneline | wc -l | tr -d ' ')
dirty=$(git -C "$PV" status --short | wc -l | tr -d ' ')
echo "  коммитов $before → $after, незакоммиченного $dirty"
if [ "$after" = "$before" ] && [ "$dirty" -gt 0 ]; then
  echo "  ok     висячего коммита не создано, данные остались в дереве"
else
  echo "  ПРОВАЛ коммит ушёл в никуда либо данные пропали"; bad=$((bad+1))
fi
# И контроль: на нормальной ветке коммит по-прежнему делается.
# `checkout -b main` здесь НЕЛЬЗЯ: ветка main уже создана `git init` и на ней сделаны оба коммита —
# команда падает, HEAD остаётся detached, и проба обвиняет исправный хук. Возвращаемся на неё.
( cd "$PV" && git checkout -q main ) >/dev/null 2>&1
n1=$(git -C "$PV" log --oneline | wc -l | tr -d ' ')
STACK_VAULT="$PV" AGENT_VAULT="$PV" bash "$HOME/.claude/hooks/session-end.sh" <<< '{"session_id":"det"}' >/dev/null 2>&1
n2=$(git -C "$PV" log --oneline | wc -l | tr -d ' ')
[ "$n2" -gt "$n1" ] && echo "  ok     на ветке авто-коммит работает" \
  || { echo "  ПРОВАЛ на ветке перестал коммитить"; bad=$((bad+1)); }
rm -rf "$PV"

echo
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
