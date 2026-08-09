#!/usr/bin/env bash
# Главная проверка после смены режима разрешений: гейт — это ХУК, он вызывается независимо от
# permission-mode, поэтому границы обязаны остаться. Если хоть одна проходит — режим надо откатывать.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
G="$HOME/.claude/hooks/guard.sh"
# РАБОЧИЙ РЕПОЗИТОРИЙ БЕРЁМ НАСТОЯЩИЙ, а не заготовку в скратчпаде: правило PUSH опознаёт его
# структурно — по кодовому корню, `--git-common-dir` и remote, — и репозиторий вне корня оно
# СПРАВЕДЛИВО считает не рабочим. Первая версия пробы этого не учла и обвинила исправный гейт в
# том, что он пропускает пуш в main. Гейт при этом ничего не выполняет: он только судит вход,
# поэтому указание на живой каталог здесь безопасно.
R="${AGENT_CODE_ROOT:-$HOME/tacticum}/tacticum-dev"
[ -d "$R/.git" ] || R="$(find "${AGENT_CODE_ROOT:-$HOME/tacticum}" -maxdepth 2 -name .git -type d 2>/dev/null | head -1 | xargs dirname 2>/dev/null)"
[ -n "$R" ] && [ -d "$R/.git" ] || { echo "не нашёл рабочего репозитория для пробы"; exit 1; }
echo "  (рабочий репозиторий для проб: $R)"
bad=0

t() { # ожидание · роль · инструмент · json tool_input · cwd · описание
  local want="$1" role="$2" tool="$3" ti="$4" dir="$5" what="$6" got json
  json=$(python3 -c 'import json,sys; print(json.dumps({"session_id":"p","cwd":sys.argv[3],"tool_name":sys.argv[1],"tool_input":json.loads(sys.argv[2])}))' "$tool" "$ti" "$dir")
  if printf '%s' "$json" | env AGENT_ROLE="$role" AGENT_CODE_ROOT="$HOME/tacticum" GUARD_TEST_RUN=1 bash "$G" 2>/dev/null | grep -q '"deny"'
  then got=deny; else got=pass; fi
  if [ "$got" = "$want" ]; then printf '  ok     %-5s %s\n' "$got" "$what"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$want" "$got" "$what"; bad=$((bad+1)); fi
}

echo "── три границы, которые обязаны держаться при любом режиме разрешений ──"
t deny director Bash "{\"command\":\"echo x >> $HOME/.claude/agent-stack.conf\"}" "$HOME" "SENTINEL: запись в файл-часовой"
t deny director Bash "{\"command\":\"git push origin main\"}" "$R" "PUSH: main рабочего репозитория"
t deny director Edit "{\"file_path\":\"$HOME/tacticum/repo/x.py\"}" "$HOME" "A2: ГД правит клиентский код"

echo "── и то, что обязано проходить (иначе роль парализована) ──"
t pass director Bash "{\"command\":\"git status --short\"}" "$R" "чтение состояния репозитория"
t pass lead     Bash "{\"command\":\"git push origin feature/x\"}" "$R" "доставка ветки в рабочий репозиторий"
t pass director Edit "{\"file_path\":\"$HOME/tacticum-vault/00-Board/card.md\"}" "$HOME" "правка доски"

echo
# Каталог НЕ удаляем: он живой рабочий репозиторий, а не заготовка пробы.
[ "$bad" -eq 0 ] && echo "провалов нет — границы держатся" || { echo "ПРОВАЛОВ $bad — режим откатить"; exit 1; }
