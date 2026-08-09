#!/usr/bin/env bash
# Проба: под стопом судится КАЖДЫЙ вызов git, включая вложенные формы.
# Сценарии девятого круга: подстановка, обратные кавычки, env-префикс, find -exec.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/k9stop"; rm -rf "$TH"; mkdir -p "$TH/.claude"
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

echo "── два git в ОДНОЙ клаузе: чтение прикрывает запись ──"
t deny 'x=$(git log -1) git commit -m wip'
t deny 'x=$(git status) git config core.hooksPath /tmp/evil'
t deny 'x=`git log -1` git commit -m wip'
t deny 'find . -maxdepth 0 -exec git status \; -exec git commit -m wip \;'
t deny 'GIT_DIR=. git status && GIT_DIR=. git commit -m x'
t deny 'echo $(git rev-parse HEAD) && git tag v9'
t deny 'for r in a b; do git -C $r status; git -C $r push origin main; done'

echo "── разделители (закрыто кругом 8, не должно сломаться) ──"
t deny "git status && git commit -m wip"
t deny "git rev-parse HEAD && git config core.hooksPath /tmp/evil"

echo "── чтение по-прежнему проходит, в том числе несколько подряд ──"
t pass 'git status --short'
t pass 'git branch -a'
t pass 'x=$(git log -1) git status'
t pass 'git log --oneline && git diff --stat && git branch -a'
t pass 'echo $(git rev-parse HEAD)'
t pass 'git remote -v; git stash list; git worktree list'
t pass 'git branch -a && git remote -v'

echo "── смешанные: чтение и запись в любом порядке ──"
t deny 'git branch feat/x && git remote -v'
t deny 'git remote -v && git branch feat/x'

echo
rm -rf "$TH"
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
