#!/usr/bin/env bash
# Проба: читающее слово у раннера засчитывается только В ПОЗИЦИИ ПОДКОМАНДЫ.
# Сценарии двенадцатого круга: слово «version» в имени пода, SELECT внутри INSERT и т.п.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/k12pos"; rm -rf "$TH"; mkdir -p "$TH/.claude"
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

echo "── читающее слово НЕ в позиции подкоманды: обязано не спасать ──"
t deny 'kubectl delete pod version-checker'
t deny 'docker kill web-info'
t deny 'docker rm ps-runner'
t deny 'go env -w GOPROXY=off'
t deny 'npm uninstall ls-tool'
t deny 'helm uninstall list-svc'

echo "── SQL: читающее слово внутри пишущего запроса ──"
t deny 'psql -c "INSERT INTO t SELECT * FROM s"'
t deny 'sqlite3 db.sqlite "DELETE FROM t WHERE id IN (SELECT id FROM s)"'
t deny 'mysql -e "DROP TABLE x; SHOW TABLES"'
t deny 'redis-cli SET k v'

echo "── настоящее чтение обязано проходить ──"
t pass 'kubectl get pods'
t pass 'docker ps'
t pass 'docker logs api --tail 50'
t pass 'go version'
t pass 'npm ls'
t pass 'helm list'
t pass 'psql -c "SELECT 1"'
t pass 'sqlite3 db.sqlite ".tables"'
t pass 'mysql -e "SHOW TABLES"'
t pass 'redis-cli GET k'

echo "── и пишущие раннеры по-прежнему не проходят ──"
t deny './deploy.sh'
t deny 'npm run build'
t deny 'terraform apply'

echo
rm -rf "$TH"
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
