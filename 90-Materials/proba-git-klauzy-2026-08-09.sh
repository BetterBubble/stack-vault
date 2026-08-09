#!/usr/bin/env bash
# Проба git под полным стопом: каждая клауза судится отдельно, читающие формы не рубятся.
# Сценарии восьмого круга: составная строка «чтение && мутация» и ложные отказы на чтении.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/k8stop"; rm -rf "$TH"; mkdir -p "$TH/.claude"
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

echo "── составные строки: мутация во ВТОРОЙ клаузе ──"
t deny "git status && git commit -m wip"
t deny "git log && git config user.name h"
t deny "git status; git push origin main"
t deny "git status && git notes add -m x HEAD"
t deny "git rev-parse HEAD && git subtree push --prefix=dist origin main"
t deny "git rev-parse HEAD && git config core.hooksPath /tmp/evil"
t deny "git log -1 && git config alias.x '!sh -c payload'"

echo "── одиночные мутации (контроль) ──"
t deny "git commit -m wip"
t deny "git config core.hooksPath /tmp/h"
t deny "git subtree push --prefix=dist origin main"

echo "── ЧТЕНИЕ обязано проходить: то, что смотрят при разборе аварии ──"
t pass "git branch -a"
t pass "git remote -v"
t pass "git stash list"
t pass "git worktree list"
t pass "git for-each-ref"
t pass "git symbolic-ref -q HEAD"
t pass "git tag -l"
t pass "git config --get user.email"
t pass "git status --short"
t pass "git log --oneline -5 && git diff --stat"
t pass "git show --stat HEAD; git rev-parse HEAD"
t pass "git submodule status"
t pass "git notes list"

echo "── двуликие в ПИШУЩЕЙ форме обязаны падать ──"
t deny "git branch feat/new"
t deny "git remote add origin https://example.com/x.git"
t deny "git stash push -m wip"
t deny "git worktree add ../wt main"
t deny "git tag v1.0"

echo
rm -rf "$TH"
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
