---
title: Журнал воркеров
type: note
status: draft
created: 2026-07-29 22:50
updated: 2026-07-29 22:50
permalink: tacticum/00-board/workers
tags:
- board
- workers
---

# Журнал воркеров

Пишется хуками SubagentStart/SubagentStop автоматически — руками не правь.
START без STOP = воркер не вернулся; повисших показывает `stack-doctor`.
Содержательный результат воркер кладёт отдельной заметкой на доску,
здесь только линия времени.

- 2026-07-30 01:30 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 01:30 START critic-doc   spawner=stack agent=acritic- sess=f34ac4a3 · 
- 2026-07-30 01:30 START auditor-scope spawner=stack agent=aauditor sess=f34ac4a3 · 
- 2026-07-30 01:37 STOP  critic-doc   spawner=stack agent=acritic- sess=f34ac4a3 · 7м · ok
