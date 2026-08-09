#!/usr/bin/env bash
# Проба: под полным стопом мутирующие git-подкоманды не проходят, читающие проходят,
# а `git subtree push` ловится правилом PUSH и БЕЗ стопа.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
G="$HOME/.claude/hooks/guard.sh"
bad=0

# ── часть 1: под нажатой кнопкой ──
TH="$S/k7stop"; rm -rf "$TH"; mkdir -p "$TH/.claude"
python3 -c "open('$TH/.claude/AGENTS_OFF','w').close()"
t() { local want="$1" cmdline="$2" got json
  json=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[2],"tool_input":{"command":sys.argv[1]}}))' "$cmdline" "$TH")
  if printf '%s' "$json" | env HOME="$TH" AGENT_ROLE=lead GUARD_TEST_RUN=1 bash "$G" 2>/dev/null | grep -q '"deny"'
  then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then printf '  ok     %-5s %s\n' "$got" "$cmdline"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$want" "$got" "$cmdline"; bad=$((bad+1)); fi
}

echo "── под стопом: мутирующее не проходит ──"
t deny "git config user.email a@b"
t deny "git notes add -m x HEAD"
t deny "git replace HEAD~1 HEAD"
t deny "git bundle create /tmp/b.bundle main"
t deny "git subtree push --prefix=sub origin main"
t deny "git subtree add --prefix=sub repo main"
t deny "git update-ref refs/heads/x HEAD"
t deny "git remote add origin https://example.com/x.git"
t deny "git commit -m x"

echo "── под стопом: чтение проходит ──"
t pass "git status --short"
t pass "git log --oneline -5"
t pass "git diff --stat"
t pass "git rev-parse HEAD"
t pass "git show --stat HEAD"
t pass "git ls-files"
t pass "git merge-base main HEAD"
t pass "git config --get user.email"
rm -rf "$TH"

# ── часть 2: без стопа — subtree push обязан ловиться правилом PUSH ──
echo "── без стопа: доставка наружу из рабочего репозитория ──"
R="$S/k7repo"; rm -rf "$R"; mkdir -p "$R"
( cd "$R" && git init -q . && git remote add origin https://gitlab.example.com/tacticum/app.git ) >/dev/null 2>&1
p() { local want="$1" cmdline="$2" got json
  json=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[2],"tool_input":{"command":sys.argv[1]}}))' "$cmdline" "$R")
  if printf '%s' "$json" | env AGENT_ROLE=stack GUARD_TEST_RUN=1 bash "$G" 2>/dev/null | grep -q '"deny"'
  then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then printf '  ok     %-5s %s\n' "$got" "$cmdline"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$want" "$got" "$cmdline"; bad=$((bad+1)); fi
}
p deny "git subtree push --prefix=sub origin main"
p deny "git push origin main"
p deny "git send-pack origin main"
rm -rf "$R"

echo
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
