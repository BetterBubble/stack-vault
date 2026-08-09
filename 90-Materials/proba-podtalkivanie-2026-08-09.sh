#!/usr/bin/env bash
# Проверка подталкивания на НАСТОЯЩЕМ формате транскрипта Claude Code (jsonl: type/message/content).
# Первая проба молчала на всех входах — и это была ошибка пробы, а не механизма: я подал
# {"role":..,"content":..}, а хук читает {"type":"assistant","message":{"content":[…]}}.
# Тот же класс, что уже стоил четырёх ложных «провалов» этой ночью: тест, не повторяющий форму
# вызова, проверяет не то.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
TH="$S/nudge2"; rm -rf "$TH"; mkdir -p "$TH/.claude"
H="$HOME/.claude/hooks/stop-nudge.sh"
T="$TH/transcript.jsonl"

mk_transcript() { # $1 — текст финального ответа роли; $2 — 1, если в ходе был вызов инструмента
  {
    printf '{"type":"user","message":{"content":[{"type":"text","text":"Сделай фичу каталога"}]}}\n'
    if [ "${2:-0}" = "1" ]; then
      printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{}}]}}\n'
      printf '{"type":"user","message":{"content":[{"type":"tool_result","content":"ok"}]}}\n'
    fi
    printf '{"type":"assistant","message":{"content":[{"type":"text","text":"%s"}]}}\n' "$1"
  } > "$T"
}

run() { printf '{"session_id":"%s","hook_event_name":"Stop","transcript_path":"%s"}' "$1" "$T" \
        | env HOME="$TH" bash "$H" 2>/dev/null; }

echo "── застрявший ход: объявил и ни одного инструмента ──"
mk_transcript "Понял задачу. Пишу план по фиче каталога." 0
n=0
for i in $(seq 1 8); do
  if [ -n "$(run "s-zastryal")" ]; then n=$((n+1)); printf '  %d: подтолкнул\n' "$i"; else printf '  %d: молчит\n' "$i"; fi
done
echo "  → подталкиваний: $n (порог подряд 2, потолок сессии 6)"
[ "$n" -ge 1 ] && [ "$n" -le 6 ] && echo "  ok — срабатывает и ограничено" || echo "  ПРОВАЛ — либо мёртв, либо без потолка"

echo "── роль реально работала (был вызов инструмента) — обязан молчать ──"
mk_transcript "Готово: поправил три файла, доктор 530 ok." 1
[ -z "$(run "s-rabotal")" ] && echo "  ok — молчит" || echo "  ПРОВАЛ — толкает того, кто работает"

echo "── законное ожидание (задал вопрос) — обязан молчать ──"
mk_transcript "Нужен твой ответ: брать вариант А или Б? Жду." 0
[ -z "$(run "s-vopros")" ] && echo "  ok — молчит" || echo "  ПРОВАЛ — толкает того, кто задал вопрос"

rm -rf "$TH"
