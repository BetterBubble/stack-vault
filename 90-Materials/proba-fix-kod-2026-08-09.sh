#!/usr/bin/env bash
# Проба: --fix правит ссылку в прозе и НЕ трогает те же строки в код-блоках и бэктиках.
# Сценарий четвёртого круга: отчёты аудита нарочно держат примеры битых ссылок в бэктиках,
# и автопочинка не должна переписывать документацию о поломке.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
V="$S/fv"; rm -rf "$V"; mkdir -p "$V/00-Board"
printf -- "---\ntitle: session-state-do-2026-08-06\n---\n\nтело\n" > "$V/00-Board/session-state-do-2026-08-06.md"

{ printf -- "---\ntitle: linker\n---\n\n"
  printf -- "Проза: [[session-state-до-2026-08-06]]\n\n"
  printf -- '```\nпример в блоке: [[session-state-до-2026-08-06]]\n```\n\n'
  printf -- "в бэктиках: \`[[session-state-до-2026-08-06]]\`\n"
} > "$V/00-Board/linker.md"

DO_FIX=1 bash "$HOME/.claude/hooks/check-links.sh" --vault "$V" --fix >/dev/null 2>&1
res="$(cat "$V/00-Board/linker.md")"

echo "── после --fix ──"
printf '%s\n' "$res" | grep -n "session-state" | sed 's/^/  /'
echo "── разбор ──"
printf '%s' "$res" | grep -q "^Проза: \[\[session-state-do-2026-08-06\]\]" \
  && echo "  ok     проза починена" || echo "  ПРОВАЛ проза не починена"
printf '%s' "$res" | grep -q "пример в блоке: \[\[session-state-до-2026-08-06\]\]" \
  && echo "  ok     код-блок не тронут" || echo "  ПРОВАЛ код-блок переписан"
printf '%s' "$res" | grep -q "в бэктиках: \`\[\[session-state-до-2026-08-06\]\]\`" \
  && echo "  ok     бэктики не тронуты" || echo "  ПРОВАЛ бэктики переписаны"
rm -rf "$V"
