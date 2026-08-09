#!/usr/bin/env bash
# Перебор под полным стопом с ОБЪЕКТ-ПЕРВЫМИ именами — класс, на котором дыру нашёл шестой круг.
# У `iva-write` имена вида `confluence_create_page`: глагол стоит вторым словом, и якорь `^`
# в шаблоне пропускал весь сервер целиком.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/k6stop"; rm -rf "$TH"; mkdir -p "$TH/.claude"
python3 -c "open('$TH/.claude/AGENTS_OFF','w').close()"
G="$HOME/.claude/hooks/guard.sh"
bad=0

t() { local want="$1" tool="$2" got
  if printf '{"session_id":"p","cwd":"%s","tool_name":"%s","tool_input":{}}' "$TH" "$tool" \
     | env HOME="$TH" AGENT_ROLE=lead GUARD_TEST_RUN=1 bash "$G" 2>/dev/null | grep -q '"deny"'
  then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then printf '  ok     %-5s %s\n' "$got" "$tool"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$want" "$got" "$tool"; bad=$((bad+1)); fi
}

echo "── объект-первые ПИШУЩИЕ (та самая дыра) ──"
for x in mcp__iva-write__confluence_create_page mcp__iva-write__jira_create_issue \
         mcp__iva-write__confluence_delete_page mcp__iva-write__jira_update_issue \
         mcp__iva-write__confluence_update_page mcp__iva-write__jira_add_comment \
         mcp__iva-write__jira_transition_issue; do t deny "$x"; done

echo "── объект-первые ЧИТАЮЩИЕ: должны проходить ──"
for x in mcp__iva-write__confluence_get_page mcp__iva-write__jira_get_issue \
         mcp__iva-write__confluence_search mcp__iva-write__jira_search; do t pass "$x"; done

echo "── чтение, в имени которого ЕСТЬ глагол записи ──"
for x in mcp__srv__get_created_pages mcp__srv__list_deployments mcp__srv__search_updates \
         mcp__srv__history_of_changes; do t pass "$x"; done

echo "── контроль: глагол-первые сохранили поведение ──"
t deny mcp__taiga__create_issue
t deny mcp__wiki-mcp__update_page
t deny mcp__basic-memory__canvas
t deny mcp__serena__activate_project
t pass mcp__taiga__list_issues
t pass mcp__basic-memory__build_context
t pass mcp__serena__open_dashboard
t pass mcp__basic-memory__read_note

echo
rm -rf "$TH"
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
