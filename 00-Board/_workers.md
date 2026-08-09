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

Пометки в строках. `?<id>` на месте типа = харнес не прислал тип воркера.
`START?` на месте длительности = у этого STOP нет парного START в журнале.
Голого `?` формат больше не пишет: раньше он означал сразу две разные поломки.
События SubagentStop, которые вообще не про воркера (харнес присылает такие на
конце хода лида), в журнал не попадают — их счётный след в
`~/.claude/logs/worker-hook-noise.log`.

Строки `STOP ?` до 2026-08-05 включительно — это те самые события конца хода,
а не пропавшие воркеры; разбор в `worker-log-fix-2026-08-05.md`. История не
переписывается, поэтому они остаются на месте.

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
- 2026-07-30 02:33 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 02:37 STOP  ?            spawner=stack agent=a51843f2 sess=f34ac4a3 ·  · ok
- 2026-07-30 02:38 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 5м · ok
- 2026-07-30 02:46 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 02:51 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 5м · ok
- 2026-07-30 02:51 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 02:52 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 1м · ok
- 2026-07-30 02:55 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 02:59 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 4м · ok
- 2026-07-30 03:02 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 03:06 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 4м · ok
- 2026-07-30 03:10 START breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 
- 2026-07-30 03:14 STOP  breaker-ssh  spawner=stack agent=abreaker sess=f34ac4a3 · 4м · ok
- 2026-07-30 03:20 STOP  ?            spawner=stack agent=a0358c49 sess=f34ac4a3 ·  · ok
- 2026-07-30 04:26 STOP  ?            spawner=stack agent=aa2de08b sess=f34ac4a3 ·  · ok
- 2026-07-30 04:30 STOP  ?            spawner=stack agent=a212842e sess=f34ac4a3 ·  · ok
- 2026-08-05 20:22 START friction-audit spawner=stack agent=africtio sess=bcd9aeb3 · 
- 2026-08-05 20:22 START usage-audit  spawner=stack agent=ausage-a sess=bcd9aeb3 · 
- 2026-08-05 20:22 START server-research spawner=stack agent=aserver- sess=bcd9aeb3 · 
- 2026-08-05 20:23 START mobile-sessions spawner=stack agent=amobile- sess=bcd9aeb3 · 
- 2026-08-05 20:23 START claude-code-guide spawner=stack agent=ad6bd1dc sess=bcd9aeb3 · 
- 2026-08-05 20:25 STOP  claude-code-guide spawner=stack agent=ad6bd1dc sess=bcd9aeb3 · 2м · ok
- 2026-08-05 20:25 STOP  mobile-sessions spawner=stack agent=amobile- sess=bcd9aeb3 · 2м · ok
- 2026-08-05 20:31 STOP  server-research spawner=stack agent=aserver- sess=bcd9aeb3 · 9м · ok
- 2026-08-05 20:33 STOP  friction-audit spawner=stack agent=africtio sess=bcd9aeb3 · 11м · ok
- 2026-08-05 20:33 STOP  usage-audit  spawner=stack agent=ausage-a sess=bcd9aeb3 · 11м · ok
- 2026-08-05 21:23 STOP  ?            spawner=stack agent=a5725454 sess=bcd9aeb3 ·  · ok
- 2026-08-05 21:33 STOP  ?            spawner=stack agent=a186f951 sess=bcd9aeb3 ·  · ok
- 2026-08-05 21:43 STOP  ?            spawner=stack agent=ac7206d7 sess=bcd9aeb3 ·  · ok
- 2026-08-05 21:53 STOP  ?            spawner=stack agent=a7aacb80 sess=bcd9aeb3 ·  · ok
- 2026-08-05 21:57 START provider-check spawner=stack agent=aprovide sess=bcd9aeb3 · 
- 2026-08-05 21:58 STOP  ?            spawner=stack agent=a584e5e3 sess=bcd9aeb3 ·  · ok
- 2026-08-05 22:04 STOP  ?            spawner=stack agent=aebdefc4 sess=bcd9aeb3 ·  · ok
- 2026-08-05 22:14 STOP  ?            spawner=stack agent=ac75f5e1 sess=bcd9aeb3 ·  · ok
- 2026-08-05 22:14 STOP  provider-check spawner=stack agent=aprovide sess=bcd9aeb3 · 17м · ok
- 2026-08-05 22:15 STOP  ?            spawner=stack agent=ab1f83f1 sess=bcd9aeb3 ·  · ok
- 2026-08-05 22:19 STOP  ?            spawner=stack agent=a4c6d1f0 sess=bcd9aeb3 ·  · ok
- 2026-08-05 22:33 STOP  ?            spawner=stack agent=a92660cf sess=bcd9aeb3 ·  · ok
- 2026-08-05 22:56 START mcp-doctor   spawner=stack agent=amcp-doc sess=bcd9aeb3 · 
- 2026-08-05 22:56 START commands-revive spawner=stack agent=acommand sess=bcd9aeb3 · 
- 2026-08-05 22:57 START worker-log-fix spawner=stack agent=aworker- sess=bcd9aeb3 · 
- 2026-08-05 22:57 START verdict-serena spawner=stack agent=averdict sess=bcd9aeb3 · 
- 2026-08-05 23:01 START general-purpose spawner=stack agent=a8a3d4b2 sess=bcd9aeb3 · 
- 2026-08-05 23:01 START general-purpose spawner=stack agent=ad9a89d5 sess=bcd9aeb3 · 
- 2026-08-05 23:01 STOP  general-purpose spawner=stack agent=a8a3d4b2 sess=bcd9aeb3 · 0м · ok
- 2026-08-05 23:01 STOP  general-purpose spawner=stack agent=ad9a89d5 sess=bcd9aeb3 · 0м · ok
- 2026-08-05 23:02 STOP  verdict-serena spawner=stack agent=averdict sess=bcd9aeb3 · 5м · ok
- 2026-08-05 23:10 STOP  commands-revive spawner=stack agent=acommand sess=bcd9aeb3 · 14м · ok
- 2026-08-05 23:13 START general-purpose spawner=stack agent=a4f1ae94 sess=bcd9aeb3 · 
- 2026-08-05 23:13 START Explore      spawner=stack agent=a1fddfe3 sess=bcd9aeb3 · 
- 2026-08-05 23:13 STOP  general-purpose spawner=stack agent=a4f1ae94 sess=bcd9aeb3 · 0м · ok
- 2026-08-05 23:13 STOP  Explore      spawner=stack agent=a1fddfe3 sess=bcd9aeb3 · 0м · ok
- 2026-08-05 23:18 STOP  mcp-doctor   spawner=stack agent=amcp-doc sess=bcd9aeb3 · 22м · ok
- 2026-08-05 23:19 STOP  worker-log-fix spawner=stack agent=aworker- sess=bcd9aeb3 · 22м · ok
- 2026-08-05 23:44 START breaker-ssh-direct spawner=stack agent=abreaker sess=bcd9aeb3 · 
- 2026-08-05 23:44 START research-orchestration spawner=stack agent=aresearc sess=bcd9aeb3 · 
- 2026-08-05 23:45 START research-guardrails spawner=stack agent=aresearc sess=bcd9aeb3 · 
- 2026-08-05 23:56 STOP  research-orchestration spawner=stack agent=aresearc sess=bcd9aeb3 · 11м · ok
- 2026-08-05 23:57 STOP  research-guardrails spawner=stack agent=aresearc sess=bcd9aeb3 · 12м · ok
- 2026-08-05 23:58 STOP  breaker-ssh-direct spawner=stack agent=abreaker sess=bcd9aeb3 · 14м · ok
- 2026-08-05 23:59 START critic-plan-approval spawner=stack agent=acritic- sess=bcd9aeb3 · 
- 2026-08-06 00:06 STOP  critic-plan-approval spawner=stack agent=acritic- sess=bcd9aeb3 · 7м · ok
- 2026-08-06 00:21 START workflow-subagent spawner=stack agent=a4f8ab95 sess=bcd9aeb3 · 
- 2026-08-06 00:23 START verify-night spawner=stack agent=averify- sess=bcd9aeb3 · 
- 2026-08-06 00:23 STOP  workflow-subagent spawner=stack agent=a4f8ab95 sess=bcd9aeb3 · 2м · ok
- 2026-08-06 00:24 START workflow-subagent spawner=stack agent=a66d8eae sess=bcd9aeb3 · 
- 2026-08-06 00:24 STOP  workflow-subagent spawner=stack agent=a66d8eae sess=bcd9aeb3 · 0м · ok
- 2026-08-06 00:27 START workflow-subagent spawner=stack agent=a021ce13 sess=bcd9aeb3 · 
- 2026-08-06 00:27 STOP  workflow-subagent spawner=stack agent=a021ce13 sess=bcd9aeb3 · 0м · ok
- 2026-08-06 00:27 START implementer  spawner=stack agent=a539c1b6 sess=bcd9aeb3 · 
- 2026-08-06 00:30 START critic-plan-approval spawner=stack agent=acritic- sess=bcd9aeb3 · 
- 2026-08-06 00:31 STOP  implementer  spawner=stack agent=a539c1b6 sess=bcd9aeb3 · 4м · ok
- 2026-08-06 00:31 START verifier     spawner=stack agent=ad3f0da6 sess=bcd9aeb3 · 
- 2026-08-06 00:32 STOP  critic-plan-approval spawner=stack agent=acritic- sess=bcd9aeb3 · 2м · ok
- 2026-08-06 00:34 START critic-plan-approval spawner=stack agent=acritic- sess=bcd9aeb3 · 
- 2026-08-06 00:35 STOP  verifier     spawner=stack agent=ad3f0da6 sess=bcd9aeb3 · 4м · ok
- 2026-08-06 00:35 START controller   spawner=stack agent=abfdd799 sess=bcd9aeb3 · 
- 2026-08-06 00:38 STOP  critic-plan-approval spawner=stack agent=acritic- sess=bcd9aeb3 · 4м · ok
- 2026-08-06 00:40 STOP  controller   spawner=stack agent=abfdd799 sess=bcd9aeb3 · 5м · ok
- 2026-08-06 00:40 START implementer  spawner=stack agent=ab4d05f2 sess=bcd9aeb3 · 
- 2026-08-06 00:43 STOP  implementer  spawner=stack agent=ab4d05f2 sess=bcd9aeb3 · 3м · ok
- 2026-08-06 00:43 START verifier     spawner=stack agent=a0aba129 sess=bcd9aeb3 · 
- 2026-08-06 00:45 STOP  verify-night spawner=stack agent=averify- sess=bcd9aeb3 · 22м · ok
- 2026-08-06 00:46 STOP  verifier     spawner=stack agent=a0aba129 sess=bcd9aeb3 · 3м · ok
- 2026-08-06 00:46 START controller   spawner=stack agent=a85a72b2 sess=bcd9aeb3 · 
- 2026-08-06 00:49 STOP  controller   spawner=stack agent=a85a72b2 sess=bcd9aeb3 · 3м · ok
- 2026-08-06 00:49 START workflow-subagent spawner=stack agent=aca2f88e sess=bcd9aeb3 · 
- 2026-08-06 00:53 STOP  workflow-subagent spawner=stack agent=aca2f88e sess=bcd9aeb3 · 4м · ok
- 2026-08-06 01:32 START memory-probe spawner=stack agent=amemory- sess=bcd9aeb3 · 
- 2026-08-06 01:34 STOP  memory-probe spawner=stack agent=amemory- sess=bcd9aeb3 · 2м · ok
- 2026-08-06 01:35 START memory-probe-2 spawner=stack agent=amemory- sess=bcd9aeb3 · 
- 2026-08-06 01:35 STOP  memory-probe-2 spawner=stack agent=amemory- sess=bcd9aeb3 · 0м · ok
- 2026-08-06 01:40 START memory-probe-3 spawner=stack agent=amemory- sess=bcd9aeb3 · 
- 2026-08-06 01:41 STOP  memory-probe-3 spawner=stack agent=amemory- sess=bcd9aeb3 · 1м · ok
- 2026-08-09 04:32 START debt-frontmatter spawner=stack agent=adebt-fr sess=33ae1170 · 
- 2026-08-09 04:32 START debt-hooks   spawner=stack agent=adebt-ho sess=33ae1170 · 
- 2026-08-09 04:33 START audit-week   spawner=stack agent=aaudit-w sess=33ae1170 · 
- 2026-08-09 04:34 START research-stacks spawner=stack agent=aresearc sess=33ae1170 · 
- 2026-08-09 04:34 START research-transcribe spawner=stack agent=aresearc sess=33ae1170 · 
- 2026-08-09 04:42 STOP  audit-week   spawner=stack agent=aaudit-w sess=33ae1170 · 9м · ok
- 2026-08-09 04:44 STOP  research-stacks spawner=stack agent=aresearc sess=33ae1170 · 10м · ok
- 2026-08-09 04:49 STOP  debt-hooks   spawner=stack agent=adebt-ho sess=33ae1170 · 17м · ok
- 2026-08-09 04:50 STOP  research-transcribe spawner=stack agent=aresearc sess=33ae1170 · 16м · ok
- 2026-08-09 04:51 STOP  debt-frontmatter spawner=stack agent=adebt-fr sess=33ae1170 · 19м · ok
- 2026-08-09 04:52 START worker-tools spawner=stack agent=aworker- sess=33ae1170 · 
- 2026-08-09 04:53 START no-approvals spawner=stack agent=ano-appr sess=33ae1170 · 
- 2026-08-09 04:53 START nudge-leads  spawner=stack agent=anudge-l sess=33ae1170 · 
- 2026-08-09 04:55 START worker-env   spawner=stack agent=aworker- sess=33ae1170 · 
- 2026-08-09 04:56 START apply-research spawner=stack agent=aapply-r sess=33ae1170 · 
- 2026-08-09 05:03 START audit-round-1 spawner=stack agent=aaudit-round-1-4f19dd4fb sess=33ae1170 · 
- 2026-08-09 05:03 START harness-output spawner=stack agent=aharness-output-f7a5b990 sess=33ae1170 · 
- 2026-08-09 05:06 STOP  harness-output spawner=stack agent=aharness-output-f7a5b990 sess=33ae1170 · 3м · ok
- 2026-08-09 05:08 STOP  apply-research spawner=stack agent=aapply-research-2c00700f sess=33ae1170 · START? · ok
