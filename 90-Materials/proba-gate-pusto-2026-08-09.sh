#!/usr/bin/env bash
# Проба: пустой план и пустые метрики роняют строгий гейт, а не проходят молча.
# Сценарий четвёртого круга аудита: «вход передан, но пуст» не должен быть неотличим от
# «всё проверено» — для деплойного гейта это худший класс.
#
# ДВА УРОКА, ОПЛАЧЕННЫХ ПЕРВОЙ ВЕРСИЕЙ ЭТОЙ ПРОБЫ:
#  1. фикстуре нужен main — без базы для сравнения гейт честно падает на ЛЮБОМ входе, и тест
#     «пустое роняет вердикт» проходил бы даже на сломанной проверке;
#  2. падение скрипта надо отличать от отказа гейта. Первая версия считала синтаксическую ошибку
#     python внутри gate-check за «fail» — и три «ok» подряд означали, что скрипт вообще не
#     запускается. Тест, который не отличает «проверка сказала нет» от «проверка не работает»,
#     хуже отсутствующего.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
R="$S/gaterepo4"; rm -rf "$R"; mkdir -p "$R"
( cd "$R" && git init -q . && git checkout -q -b main \
  && printf 'x\n' > a.txt && git add -A && git -c user.email=t@t -c user.name=t commit -qm init \
  && git checkout -q -b feat/k4 \
  && printf 'y\n' > b.txt && git add -A && git -c user.email=t@t -c user.name=t commit -qm work ) >/dev/null 2>&1

: > "$S/plan-empty.md"
printf '{}' > "$S/m-empty.json"
printf 'апрув: Президент, 09.08 в чате\n\n## Что НЕ трогаем\nсоседние фичи\n' > "$S/plan-ok.md"
printf '{"recall":{"value":0.7,"threshold":0.62}}' > "$S/m-ok.json"

check() { # описание · ожидание(fail|pass) · аргументы
  local what="$1" want="$2"; shift 2
  local out ok got
  out="$(GATE_STRICT=1 GATE_ACK_UNCHECKED="скоуп,гейт приёмки материалов" \
         bash "$HOME/.claude/hooks/gate-check.sh" "$R" "$@" --json 2>/dev/null)"
  ok="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("ok_overall"))' 2>/dev/null)"
  case "$ok" in
    True)  got=pass ;;
    False) got=fail ;;
    *)     printf '  СЛОМАН гейт не вернул разбираемый JSON — %s\n' "$what"; return ;;
  esac
  if [ "$got" = "$want" ]; then printf '  ok     %-4s %s\n' "$got" "$what"
  else printf '  ПРОВАЛ ждали %s, вышло %s — %s\n' "$want" "$got" "$what"; fi
}

echo "── пустые входы обязаны ронять вердикт ──"
check "пустой файл плана"          fail --plan "$S/plan-empty.md" --metrics "$S/m-ok.json"
check "пустой объект метрик"       fail --plan "$S/plan-ok.md"    --metrics "$S/m-empty.json"
check "оба пустых"                 fail --plan "$S/plan-empty.md" --metrics "$S/m-empty.json"

echo "── заполненные входы по-прежнему проходят ──"
check "нормальный план и метрики"  pass --plan "$S/plan-ok.md"    --metrics "$S/m-ok.json"

rm -rf "$R" "$S/plan-empty.md" "$S/m-empty.json" "$S/plan-ok.md" "$S/m-ok.json"
