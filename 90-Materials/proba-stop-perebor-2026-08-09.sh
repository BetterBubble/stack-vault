#!/usr/bin/env bash
# Перебор инструментов живых MCP-серверов под нажатой кнопкой стопа: что пишет — не должно
# проходить, что читает — должно. Приём четвёртого круга аудита: шаблон по глаголам ловит
# большинство, а исключения находит только перебор реального списка имён.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/perebor"; rm -rf "$TH"; mkdir -p "$TH/.claude"
python3 -c "open('$TH/.claude/AGENTS_OFF','w').close()"
G="$HOME/.claude/hooks/guard.sh"
bad=0

t() { # ожидание · инструмент
  local want="$1" tool="$2" got
  if printf '{"session_id":"p","cwd":"%s","tool_name":"%s","tool_input":{}}' "$TH" "$tool" \
     | env HOME="$TH" AGENT_ROLE=lead GUARD_TEST_RUN=1 bash "$G" 2>/dev/null | grep -q '"deny"'
  then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then printf '  ok     %-5s %s\n' "$got" "$tool"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$want" "$got" "$tool"; bad=$((bad+1)); fi
}

echo "── пишущие: обязаны не пройти ──"
for x in mcp__basic-memory__canvas mcp__basic-memory__write_note mcp__basic-memory__edit_note \
         mcp__basic-memory__move_note mcp__basic-memory__create_memory_project \
         mcp__serena__replace_symbol_body mcp__serena__safe_delete_symbol \
         mcp__serena__write_memory mcp__taiga__create_issue mcp__taiga__add_comment \
         mcp__wiki-mcp__update_page; do t deny "$x"; done

echo "── читающие: обязаны пройти ──"
for x in mcp__basic-memory__read_note mcp__basic-memory__search_notes \
         mcp__basic-memory__build_context mcp__basic-memory__list_directory \
         mcp__basic-memory__recent_activity mcp__serena__find_symbol \
         mcp__serena__get_symbols_overview mcp__taiga__list_issues mcp__taiga__get_issue \
         mcp__wiki-mcp__get_page; do t pass "$x"; done

echo
rm -rf "$TH"
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
