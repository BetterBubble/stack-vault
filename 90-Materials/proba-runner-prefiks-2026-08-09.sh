#!/usr/bin/env bash
# Проба: раннер ловится и когда перед ним стоит присваивание или подстановка.
# Сценарий тринадцатого круга: `PGPASSWORD=secret psql -c "UPDATE …"` проходил мимо стопа.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/k13pref"; rm -rf "$TH"; mkdir -p "$TH/.claude"
python3 -c "open('$TH/.claude/AGENTS_OFF','w').close()"
G="$HOME/.claude/hooks/guard.sh"
bad=0

t() { local want="$1" cmdline="$2" got json
  json=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[2],"tool_input":{"command":sys.argv[1]}}))' "$cmdline" "$TH")
  if printf '%s' "$json" | env HOME="$TH" AGENT_ROLE=lead GUARD_TEST_RUN=1 bash "$G" 2>/dev/null | grep -q '"deny"'
  then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then printf '  ok     %-5s %s\n' "$got" "$cmdline"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$want" "$got" "$cmdline"; bad=$((bad+1)); fi
}

echo "── присваивание перед раннером: обычный идиом, не обфускация ──"
t deny 'PGPASSWORD=secret psql -c "UPDATE t SET x=1"'
t deny 'MYSQL_PWD=x mysql -e "DROP TABLE t"'
t deny 'FOO=1 ./deploy.sh'
t deny 'NODE_ENV=production npm run build'
t deny 'AWS_PROFILE=prod terraform apply'
t deny 'KUBECONFIG=/tmp/c kubectl delete pod x'

echo "── подстановка и скобки ──"
t deny 'x=$(make deploy)'
t deny 'out=$(npm run build)'
t deny 'r=`terraform apply`'
t deny '(cd /tmp && ./deploy.sh)'
t deny 'if true; then ./deploy.sh; fi'
t deny 'for d in a b; do make -C $d all; done'

echo "── чтение с теми же префиксами обязано проходить ──"
t pass 'PGPASSWORD=secret psql -c "SELECT 1"'
t pass 'KUBECONFIG=/tmp/c kubectl get pods'
t pass 'x=$(docker ps)'
t pass 'NODE_ENV=test npm ls'
t pass 'out=$(kubectl get pods)'
t pass 'if true; then docker ps; fi'

echo "── контроль: git те же формы ловил и раньше ──"
t deny 'FOO=bar git commit -m x'
t pass 'FOO=bar git status'

echo
rm -rf "$TH"
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
