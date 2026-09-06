---
title: План — README каталога tools в claude-stack
type: note
status: current
created: 2026-09-06 05:50
updated: 2026-09-06 05:50
permalink: stack/coordination/plan-tools-readme
tags:
- board
- plan
---

# План: README каталога tools/ в claude-stack

апрув: Президент, 06.09 в чате (мандат ночи: «все права и разрешения тебе даю, делай всё»)
autonomy: on

## Что сделаем
Файл `tools/README.md` в репозитории `~/claude-stack`: по абзацу на каждый инструмент каталога
(mac-bridge, mac-get, mac-fetch-hook, stack-watchdog, install-watchdog, srv-team, srv-tabs,
work, transcribe-роли и прочие .sh) — что делает, где ставится (мак/сервер), как запускается.
Источник — шапки самих скриптов, не выдумывать.

## Как это будет выглядеть
Один markdown-файл `tools/README.md`: таблица «инструмент · что делает · где живёт · запуск»
плюс короткие секции по нетривиальным (мост, watchdog). Читается за две минуты.

## Что НЕ трогаем
Сами скрипты tools/*.sh — ни строчки. Остальные файлы claude-stack (регламенты, персоны,
roles.zsh). Конфиги ~/.claude. Сервер. Это задача ТОЛЬКО про один новый файл README.

scope:
  - tools/README.md

acceptance:
  - tools_described >= 8
