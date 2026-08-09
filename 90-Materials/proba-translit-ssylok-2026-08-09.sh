#!/usr/bin/env bash
# Проба транслита в чекере ссылок: чинит однозначное, не трогает кликающееся, молчит на спорном.
# Сценарий взят у третьего круга аудита — он же и вскрыл дефект.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
V="$S/clvault"; rm -rf "$V"; mkdir -p "$V/00-Board"
w() { printf -- "---\ntitle: %s\n---\n\n%s\n" "$1" "${2:-текст}" > "$V/00-Board/$1.md"; }

w "дело"                       # кириллицей
w "delo"                       # ДРУГАЯ заметка, латиницей
w "мир"
w "mir"                        # тоже другая
w "session-state-do-2026-08-06"  # однозначный транслит-кандидат
{
  printf -- "---\ntitle: linker\n---\n\n"
  printf -- "ссылка регистром: [[Дело]]\n"           # кликается в Obsidian, чинить НЕЛЬЗЯ
  printf -- "спорный транслит: [[миръ]]\n"           # два кандидата — цель неизвестна
  printf -- "однозначный: [[session-state-до-2026-08-06]]\n"   # чинится верно
} > "$V/00-Board/linker.md"

echo "── прогон ──"
out="$(bash "$HOME/.claude/hooks/check-links.sh" --vault "$V" 2>&1)"
printf '%s\n' "$out" | grep -E "Итого|←" | head -10

echo
echo "── разбор ──"
if printf '%s' "$out" | grep -q "delo"; then
  echo "  ПРОВАЛ: [[Дело]] предлагается перешить на delo.md — это ДРУГАЯ заметка"
else
  echo "  ok: [[Дело]] не перешивается на чужую заметку"
fi
if printf '%s' "$out" | grep -qE "\[\[миръ\]\].*mir\b"; then
  echo "  ПРОВАЛ: спорный транслит выдан как точная цель"
else
  echo "  ok: спорный транслит не выдан за точную цель"
fi
if printf '%s' "$out" | grep -q "session-state-do-2026-08-06"; then
  echo "  ok: однозначный транслит по-прежнему чинится"
else
  echo "  ПРОВАЛ: однозначный транслит перестал определяться — потеряли починку круга 2"
fi
rm -rf "$V"
