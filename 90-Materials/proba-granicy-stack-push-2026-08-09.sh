#!/usr/bin/env bash
# Проба правила STACK-PUSH: наружу только четыре личных репозитория.
G="$HOME/.claude/hooks/guard.sh"
ok=0; bad=0

t() { # роль · ожидание · описание · cwd · команда
  local role="$1" want="$2" what="$3" dir="$4" cmdline="$5" got json
  # cwd лежит на ВЕРХНЕМ уровне входа хука, не внутри tool_input. Первая версия этой пробы клала
  # его в tool_input — и четыре случая «прошли», хотя гейт исправен: он просто не видел каталога.
  json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","cwd":sys.argv[2],"tool_input":{"command":sys.argv[1]}}))' "$cmdline" "$dir")
  if printf '%s' "$json" | AGENT_ROLE="$role" bash "$G" 2>/dev/null | grep -q '"deny"'; then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then ok=$((ok+1)); printf '  ok     %-9s %-5s %s\n' "$role" "$got" "$what"
  else bad=$((bad+1)); printf '  ПРОВАЛ %-9s ждали %s, получили %s — %s\n' "$role" "$want" "$got" "$what"; fi
}

echo "── роль stack: личные репозитории разрешены целиком, включая main ──"
t stack pass "claude-stack, main"        "$HOME/claude-stack" "git push origin main"
t stack pass "stack-vault, main"         "$HOME/stack-vault"  "git push origin main"
t stack pass "claude-config (~/.claude)" "$HOME/.claude"      "git push origin main"
t stack pass "work-vault"                "$HOME/tacticum-vault" "git push origin main"
t stack pass "личный репо, ветка"        "$HOME/claude-stack" "git push origin feature/x"

echo "── роль stack: наружу в чужое — запрет ──"
t stack deny "рабочий репозиторий, ветка" "$HOME/tacticum"    "git push origin feature/x"
t stack deny "рабочий репозиторий, main"  "$HOME/tacticum"    "git push origin main"
t stack deny "пуш без remote"             "$HOME/claude-stack" "git push"
t stack deny "неизвестный remote"         "$HOME/claude-stack" "git push upstream main"

echo "── рабочие роли: правила не изменились ──"
t director pass "доставка ветки в рабочий"  "$HOME/tacticum" "git push origin feature/x"
t director deny "main рабочего репозитория" "$HOME/tacticum" "git push origin main"
t lead     deny "force в рабочий"           "$HOME/tacticum" "git push --force origin feature/x"
t director pass "личный репозиторий"        "$HOME/claude-stack" "git push origin main"

echo
if [ "$bad" -eq 0 ]; then echo "ИТОГ: $ok ok, провалов нет"; else echo "ИТОГ: $ok ok, ПРОВАЛОВ $bad"; exit 1; fi
