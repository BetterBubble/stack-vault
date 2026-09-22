---
title: gate-check пропускает файлы вне скоупа при шаблоне с **
type: note
status: open
created: 2026-09-21 13:00
tags:
- debt
- gate-check
permalink: stack/40-debt/gate-check-scope-dvoynaya-zvezda
---

# gate-check `--scope` пропускает файлы вне скоупа

21.09.2026, гейт ветки ai-paas `feat/strict-134`: контролёр руками нашёл 6 файлов вне `scope:` плана, скрипт назвал 5 — не увидел `test/e2e/run/run_test.go`. Похоже на неверное сопоставление шаблонов с `**`.

Откуда: вердикт `controller-aipaas-strict-134-2026-09-21` в рабочем vault (32 — Выхлоп воркеров). Чинить в роли `stack`.