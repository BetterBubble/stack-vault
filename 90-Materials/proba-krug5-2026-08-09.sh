#!/usr/bin/env bash
# Пробы по находкам пятого круга: активация проекта под стопом, легенда в счёте веток,
# сверка норм по регистру кириллицы.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
G="$HOME/.claude/hooks/guard.sh"
bad=0

echo "── activate_project пишет на диск, значит под стопом не проходит ──"
TH="$S/k5stop"; rm -rf "$TH"; mkdir -p "$TH/.claude"
python3 -c "open('$TH/.claude/AGENTS_OFF','w').close()"
for pair in "deny mcp__serena__activate_project" "deny mcp__basic-memory__canvas" \
            "pass mcp__serena__find_symbol" "pass mcp__serena__open_dashboard"; do
  want="${pair%% *}"; tool="${pair#* }"
  if printf '{"session_id":"p","cwd":"%s","tool_name":"%s","tool_input":{}}' "$TH" "$tool" \
     | env HOME="$TH" AGENT_ROLE=lead GUARD_TEST_RUN=1 bash "$G" 2>/dev/null | grep -q '"deny"'
  then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then printf '  ok     %-5s %s\n' "$got" "$tool"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$want" "$got" "$tool"; bad=$((bad+1)); fi
done
rm -rf "$TH"

echo "── сверка норм ловит ЗАГЛАВНУЮ форму, на которой споткнулась ──"
CH="$S/k5roles"; CP="$S/k5agents"; rm -rf "$CH" "$CP"; mkdir -p "$CH" "$CP"
printf 'charter\n' > "$CH/lead.md"
printf 'решение Президента 2026-08-05 ВЕРНУЛО апрув плана\n' > "$CP/lead.md"
if grep -qE "2026-08-05 (вернул|ВЕРНУЛ)|05\.08 (вернул|ВЕРНУЛ)" "$CP/lead.md"; then
  echo "  ok     заглавная «ВЕРНУЛО» ловится"
else
  echo "  ПРОВАЛ заглавная форма проходит мимо — проверка не поймала бы исходный дефект"; bad=$((bad+1))
fi
printf 'решение Президента 2026-08-05 вернуло апрув плана\n' > "$CP/lead.md"
grep -qE "2026-08-05 (вернул|ВЕРНУЛ)" "$CP/lead.md" && echo "  ok     строчная форма ловится" \
  || { echo "  ПРОВАЛ строчная форма потеряна"; bad=$((bad+1)); }
printf 'с 2026-08-09 разметка плана не условие старта\n' > "$CP/lead.md"
grep -qE "2026-08-05 (вернул|ВЕРНУЛ)" "$CP/lead.md" && { echo "  ПРОВАЛ ложное срабатывание"; bad=$((bad+1)); } \
  || echo "  ok     на актуальном тексте молчит"
rm -rf "$CH" "$CP"

echo
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
