#!/usr/bin/env bash
# Проба: под полным стопом раннеры и прямой запуск скрипта не проходят, чтение проходит.
# Сценарий одиннадцатого круга: `bash deploy.sh` отказывался, а `./deploy.sh` — нет.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/k11stop"; rm -rf "$TH"; mkdir -p "$TH/.claude"
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

echo "── прямой запуск скрипта: то же, что bash script.sh ──"
t deny "./deploy.sh"
t deny "scripts/deploy.sh"
t deny "./tools/build.py"
t deny "bash deploy.sh"

echo "── раннеры произвольных рецептов ──"
t deny "make deploy"
t deny "make -C build all"
t deny "npm run build"
t deny "npm ci"
t deny "npx prettier --write ."
t deny "yarn build"
t deny "pnpm install"
t deny "cargo build"
t deny "go build ./..."
t deny "docker compose up -d"
t deny "kubectl apply -f k8s/"
t deny "terraform apply"

echo "── запись без глагола ──"
t deny "tar -xf archive.tar"
t deny "unzip pack.zip"
t deny "sqlite3 db.sqlite 'DELETE FROM t'"
t deny "rsync -av src/ dst/"
t deny "dd if=/dev/zero of=/tmp/f bs=1M count=1"

echo "── ЧТЕНИЕ под стопом обязано проходить ──"
t pass "git status --short"
t pass "git log --oneline -5"
t pass "ls -la"
t pass "cat README.md"
t pass "grep -rn TODO src/"
t pass "head -20 file.txt"
t pass "wc -l file.txt"
t pass "find . -name '*.md'"

echo
rm -rf "$TH"
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
