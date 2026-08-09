#!/usr/bin/env bash
# Проверка риска, заложенного запретом раннеров: рубит ли он ЧИТАЮЩИЕ формы тех же команд.
# Под стопом чтение обязано работать — иначе человек не сможет разобрать аварию.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/k12read"; rm -rf "$TH"; mkdir -p "$TH/.claude"
python3 -c "open('$TH/.claude/AGENTS_OFF','w').close()"
G="$HOME/.claude/hooks/guard.sh"

t() { local cmdline="$1" got json
  json=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[2],"tool_input":{"command":sys.argv[1]}}))' "$cmdline" "$TH")
  if printf '%s' "$json" | env HOME="$TH" AGENT_ROLE=lead GUARD_TEST_RUN=1 bash "$G" 2>/dev/null | grep -q '"deny"'
  then got=deny; else got=pass; fi
  printf '  %-5s %s\n' "$got" "$cmdline"
}

echo "── читающие формы раннеров: что происходит сейчас ──"
for c in "docker ps" "docker logs api --tail 50" "docker images" "docker inspect api" \
         "kubectl get pods" "kubectl logs pod-1" "kubectl describe pod pod-1" \
         "helm list" "npm ls" "npm view react version" "make -n deploy" \
         "go version" "cargo --version" "tar -tf archive.tar" \
         "sqlite3 db.sqlite .tables" "psql -c 'SELECT 1'" "rsync --dry-run -av a/ b/"; do
  t "$c"
done
rm -rf "$TH"
