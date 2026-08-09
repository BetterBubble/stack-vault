#!/usr/bin/env bash
# Проба авто-коммита памяти в session-end.sh: коммитит, когда есть что, и молчит, когда нечего.
set -e
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
V="$S/probe-vault"
rm -rf "$V"; mkdir -p "$V"
cd "$V"
git init -q .
git config user.email probe@local; git config user.name probe
printf 'первая\n' > a.md
git add -A; git commit -q -m init
before=$(git log --oneline | wc -l | tr -d ' ')

# ── случай 1: есть незакоммиченное → хук обязан закоммитить
printf 'вторая\n' > b.md
dirty=$(git status --short | wc -l | tr -d ' ')
AGENT_VAULT="$V" bash "$HOME/.claude/hooks/session-end.sh" <<< '{"session_id":"proba123"}' >/dev/null 2>&1
after=$(git log --oneline | wc -l | tr -d ' ')
left=$(git status --short | wc -l | tr -d ' ')
echo "случай 1 (было незакоммичено $dirty): коммитов $before → $after, осталось грязных $left"
[ "$after" -gt "$before" ] && [ "$left" -eq 0 ] && echo "  ok  закоммитил" || { echo "  ПРОВАЛ не закоммитил"; exit 1; }
echo "  сообщение: $(git log -1 --pretty=%s)"

# ── случай 2: чисто → хук обязан молчать, а не плодить пустые коммиты
AGENT_VAULT="$V" bash "$HOME/.claude/hooks/session-end.sh" <<< '{"session_id":"proba123"}' >/dev/null 2>&1
after2=$(git log --oneline | wc -l | tr -d ' ')
echo "случай 2 (чисто): коммитов $after → $after2"
[ "$after2" -eq "$after" ] && echo "  ok  пустого коммита не создал" || { echo "  ПРОВАЛ создал пустой коммит"; exit 1; }

# ── случай 3: новый неотслеживаемый файл (частый случай — новая заметка)
printf 'третья\n' > c.md
AGENT_VAULT="$V" bash "$HOME/.claude/hooks/session-end.sh" <<< '{"session_id":"proba123"}' >/dev/null 2>&1
after3=$(git log --oneline | wc -l | tr -d ' ')
echo "случай 3 (новый файл): коммитов $after2 → $after3"
[ "$after3" -gt "$after2" ] && echo "  ok  новую заметку подхватил" || { echo "  ПРОВАЛ новый файл не попал в коммит"; exit 1; }

# ── случай 4: каталог не репозиторий → хук не должен падать
mkdir -p "$S/probe-notgit"
AGENT_VAULT="$S/probe-notgit" bash "$HOME/.claude/hooks/session-end.sh" <<< '{"session_id":"proba123"}' >/dev/null 2>&1
echo "случай 4 (не репозиторий): код возврата $? — ok, хук не упал"

rm -rf "$V" "$S/probe-notgit"
echo "ИТОГ: все четыре случая прошли"
