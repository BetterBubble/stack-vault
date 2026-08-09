#!/usr/bin/env bash
# Проба: строка баннера про очередь мержа считает ветки, а не шапку таблицы.
# Кэш подсовываем готовый — так проверяется именно подсчёт, без похода по репозиториям.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/bhome"; rm -rf "$TH"; mkdir -p "$TH/.claude/hooks" "$TH/tacticum-vault/01-Sessions"
cp "$HOME/.claude/hooks/session-start.sh" "$TH/.claude/hooks/"
# Заглушки для того, что старт зовёт помимо баннера.
for h in memory-maintenance.sh waiting-queue.sh signal-status.sh pr-queue.sh role-register.sh; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TH/.claude/hooks/$h"; chmod +x "$TH/.claude/hooks/$h"
done

run() { printf '{"session_id":"b","hook_event_name":"SessionStart"}' \
        | env HOME="$TH" CLAUDE_STARTUP_CONTEXT=1 AGENT_ROLE=director \
              AGENT_VAULT="$TH/tacticum-vault" bash "$TH/.claude/hooks/session-start.sh" 2>/dev/null \
        | grep "веток ждёт мержа" || echo "(строки нет)"; }

echo "── одна СВЕЖАЯ ветка: протухших ноль ──"
{ printf '── Ветки, ждущие мержа ──\n'
  printf '  !  дн  отстал  репозиторий         ветка\n'
  printf '      0      1  repo1              feat/svezhaya\n'
} > "$TH/.claude/.pr-queue-cache"
out="$(run)"; echo "  $out"
printf '%s' "$out" | grep -q "все свежие" && echo "  ok — шапка не посчитана веткой" \
                                          || echo "  ПРОВАЛ — протухание там, где его нет"

echo "── две ветки, одна протухла ──"
{ printf '── Ветки, ждущие мержа ──\n'
  printf '  !  дн  отстал  репозиторий         ветка\n'
  printf '  !  35    877  repo1              feat/staraya\n'
  printf '      0      1  repo1              feat/svezhaya\n'
  printf '\n  ! — стоит ≥2 дн И основная ветка ушла вперёд: подлить её и перегнать гейт,\n'
} > "$TH/.claude/.pr-queue-cache"
out="$(run)"; echo "  $out"
printf '%s' "$out" | grep -q "мержа: 2, из них протухло 1" && echo "  ok — легенда не посчитана веткой" \
                                                           || echo "  ПРОВАЛ — счёт неверен"
rm -rf "$TH"
