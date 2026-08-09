#!/usr/bin/env bash
# Проба: при нажатой кнопке AGENTS_OFF гейт ловит ВСЕ write-инструменты MCP, включая те,
# которых нет ни в одном списке (taiga, wiki, helm) — их матчер раньше не поднимал вовсе.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/ph-stop"; rm -rf "$TH"; mkdir -p "$TH/.claude"
# Кнопку создаём питоном: Bash-ветка гейта ловит само имя файла в любом каталоге, и обычный
# `touch` здесь получил бы отказ — правило шире, чем нужно, но это не предмет этой пробы.
python3 -c "open('$TH/.claude/AGENTS_OFF','w').close()"
G="$HOME/.claude/hooks/guard.sh"
ok=0; bad=0

t() { # ожидание · инструмент · описание
  local want="$1" tool="$2" what="$3" got
  if printf '{"session_id":"p","cwd":"%s","tool_name":"%s","tool_input":{}}' "$TH" "$tool" \
     | env HOME="$TH" AGENT_ROLE=lead GUARD_TEST_RUN=1 bash "$G" 2>/dev/null | grep -q '"deny"'
  then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then ok=$((ok+1)); printf '  ok     %-5s %-32s %s\n' "$got" "$tool" "$what"
  else bad=$((bad+1)); printf '  ПРОВАЛ ждали %s, вышло %s — %-32s %s\n' "$want" "$got" "$tool" "$what"; fi
}

echo "── стоп нажат: запись через ЛЮБОЙ MCP-сервер не проходит ──"
t deny mcp__taiga__create_issue      "создать задачу в трекере"
t deny mcp__taiga__update_user_story "изменить историю"
t deny mcp__wiki-mcp__update_page    "править страницу вики"
t deny mcp__helm-analyst__apply      "применить через аналитика"
t deny mcp__serena__replace_content  "правка кода (ловилось и раньше)"
t deny mcp__basic-memory__write_note "запись в память (ловилось и раньше)"

echo "── стоп нажат: ЧТЕНИЕ по-прежнему свободно ──"
t pass mcp__taiga__list_issues       "посмотреть задачи"
t pass mcp__taiga__get_issue         "открыть задачу"
t pass mcp__wiki-mcp__get_page       "прочитать страницу вики"
t pass mcp__serena__find_symbol      "найти символ в коде"

echo
rm -rf "$TH"
if [ "$bad" -eq 0 ]; then echo "ИТОГ: $ok ok, провалов нет"; else echo "ИТОГ: $ok ok, ПРОВАЛОВ $bad"; exit 1; fi
