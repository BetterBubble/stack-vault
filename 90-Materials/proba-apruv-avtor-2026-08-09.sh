#!/usr/bin/env bash
# Проба: гейт честно называет автора апрува на ВСЕХ трёх формах нормы, дословно.
# Сценарий пятнадцатого круга: `апрув: ГД, 06.08 (Президент недоступен)` объявлялся «апрувом
# человека», потому что слово «Президент» стоит в скобке и ловилось поиском по всей строке.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
R="$S/aprepo"; rm -rf "$R"; mkdir -p "$R"
( cd "$R" && git init -q . && git checkout -q -b main && printf 'x\n' > a.txt && git add -A \
  && git -c user.email=t@t -c user.name=t commit -qm init && git checkout -q -b feat/x \
  && printf 'y\n' > b.txt && git add -A && git -c user.email=t@t -c user.name=t commit -qm work ) >/dev/null 2>&1
bad=0

t() { # ожидаемый вид апрува · строка апрува · описание
  local want="$1" line="$2" what="$3"
  printf '%s\n\n## Что НЕ трогаем\nсоседние фичи\n' "$line" > "$S/p.md"
  local out kind
  out="$(bash "$HOME/.claude/hooks/gate-check.sh" "$R" --plan "$S/p.md" --json 2>/dev/null)"
  kind="$(printf '%s' "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
c=[x for x in d["checks"] if "строка апрува" in x["name"]]
print(c[0]["detail"] if c else "(нет проверки)")' 2>/dev/null)"
  if printf '%s' "$kind" | grep -q "апрув $want"; then printf '  ok     %-22s %s\n' "$want" "$what"
  else printf '  ПРОВАЛ ждали «%s», вышло «%s» — %s\n' "$want" "$kind" "$what"; bad=$((bad+1)); fi
}

echo "── три формы нормы, дословно ──"
t "человек"             "апрув: Президент, 09.08 в чате"                  "слово Президента"
t "самовыданный агентом" "апрув: ГД, 06.08 (Президент недоступен)"        "каноничная форма ГД — слово в скобке"
t "самовыданный агентом" "апрув: лид, 09.08 (план не размечал никто)"     "форма лида"
echo "── и варианты, где имя стоит иначе ──"
t "самовыданный агентом" "апрув: ГД, 09.08"                              "ГД без скобки"
t "человек"             "апрув: Президент"                                "только имя"
t "самовыданный агентом" "апрув: director, 09.08 (ждали Президента)"      "латиницей, слово в скобке"

rm -rf "$R" "$S/p.md"
[ "$bad" -eq 0 ] && echo "провалов нет" || { echo "ПРОВАЛОВ $bad"; exit 1; }
