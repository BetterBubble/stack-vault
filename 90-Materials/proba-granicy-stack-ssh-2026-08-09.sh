#!/usr/bin/env bash
# Проба правила STACK: сервер запрещён роли stack и разрешён рабочим ролям.
# Каждый случай — вход хука целиком, как его отдаёт харнесс.
G="$HOME/.claude/hooks/guard.sh"
ok=0; bad=0

t() { # роль · ожидание (deny|pass) · описание · json
  local role="$1" want="$2" what="$3" json="$4" got
  if printf '%s' "$json" | AGENT_ROLE="$role" bash "$G" 2>/dev/null | grep -q '"deny"'; then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then ok=$((ok+1)); printf '  ok    %-9s %-6s %s\n' "$role" "$got" "$what"
  else bad=$((bad+1)); printf '  ПРОВАЛ %-9s ждали %s, получили %s — %s\n' "$role" "$want" "$got" "$what"; fi
}

echo "── роль stack: сервер запрещён целиком ──"
t stack deny "ssh на чтение логов"        '{"tool_name":"Bash","tool_input":{"command":"ssh prod \"tail -n 20 /var/log/app.log\""}}'
t stack deny "ssh без команды (шелл)"     '{"tool_name":"Bash","tool_input":{"command":"ssh prod"}}'
t stack deny "scp скачивание с сервера"   '{"tool_name":"Bash","tool_input":{"command":"scp prod:/var/log/app.log ."}}'
t stack deny "rsync с сервера"            '{"tool_name":"Bash","tool_input":{"command":"rsync -av prod:/srv/app/ ./local/"}}'
t stack deny "mosh"                       '{"tool_name":"Bash","tool_input":{"command":"mosh prod"}}'
t stack deny "ansible сухой прогон"       '{"tool_name":"Bash","tool_input":{"command":"ansible-playbook site.yml --check"}}'
t stack deny "ssh через переменную"       '{"tool_name":"Bash","tool_input":{"command":"X=ssh; $X prod uptime"}}'
t stack deny "ssh полным путём"           '{"tool_name":"Bash","tool_input":{"command":"/usr/bin/ssh prod uptime"}}'
t stack deny "MCP: health check"          '{"tool_name":"mcp__ssh-manager__ssh_health_check","tool_input":{}}'
t stack deny "MCP: список серверов"       '{"tool_name":"mcp__ssh-manager__ssh_list_servers","tool_input":{}}'
t stack deny "MCP: выполнить команду"     '{"tool_name":"mcp__ssh-manager__ssh_execute","tool_input":{"command":"uptime"}}'

echo "── роль stack: локальное НЕ ловится (ложные отказы) ──"
t stack pass "grep слова ssh в файле"     '{"tool_name":"Bash","tool_input":{"command":"grep ssh ~/notes.md"}}'
t stack pass "echo ssh в файл"            '{"tool_name":"Bash","tool_input":{"command":"echo ssh > /tmp/probe-f"}}'
t stack pass "git status"                 '{"tool_name":"Bash","tool_input":{"command":"git status --short"}}'
t stack pass "правка файла стека"         '{"tool_name":"Edit","tool_input":{"file_path":"/Users/bubblemac/claude-stack/README.md","old_string":"a","new_string":"b"}}'
t stack pass "правка в tacticum локально" '{"tool_name":"Edit","tool_input":{"file_path":"/Users/bubblemac/tacticum/.mcp.json","old_string":"a","new_string":"b"}}'

echo "── рабочие роли: сервер по-прежнему доступен ──"
t director pass "ssh на чтение логов"     '{"tool_name":"Bash","tool_input":{"command":"ssh prod \"tail -n 20 /var/log/app.log\""}}'
t director pass "MCP: health check"       '{"tool_name":"mcp__ssh-manager__ssh_health_check","tool_input":{}}'
t lead     pass "MCP: список серверов"    '{"tool_name":"mcp__ssh-manager__ssh_list_servers","tool_input":{}}'
t lead     pass "ssh чтение через MCP"    '{"tool_name":"mcp__ssh-manager__ssh_tail","tool_input":{"path":"/var/log/app.log"}}'

echo
if [ "$bad" -eq 0 ]; then echo "ИТОГ: $ok ok, провалов нет"; else echo "ИТОГ: $ok ok, ПРОВАЛОВ $bad"; exit 1; fi
