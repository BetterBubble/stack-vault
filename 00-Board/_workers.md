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
- 2026-07-30 01:40 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 10м · ok
- 2026-07-30 01:41 STOP  auditor-scope spawner=stack agent=aauditor sess=f34ac4a3 · 11м · ok
- 2026-07-30 01:42 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 01:42 START auditor-scope spawner=stack agent=aauditor sess=f34ac4a3 · 
- 2026-07-30 01:44 STOP  auditor-scope spawner=stack agent=aauditor sess=f34ac4a3 · 2м · ok
- 2026-07-30 01:44 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 2м · ok
- 2026-07-30 01:46 START critic-doc   spawner=stack agent=acritic- sess=f34ac4a3 · 
- 2026-07-30 01:48 STOP  critic-doc   spawner=stack agent=acritic- sess=f34ac4a3 · 2м · ok
- 2026-07-30 02:06 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 02:14 STOP  ?            spawner=stack agent=ad7544d3 sess=f34ac4a3 ·  · ok
- 2026-07-30 02:15 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 9м · ok
- 2026-07-30 02:20 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 02:27 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 7м · ok
- 2026-07-30 02:27 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 02:28 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 1м · ok
