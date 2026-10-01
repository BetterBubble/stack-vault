---
title: Хроника работы над стеком — октябрь 2026
type: note
status: current
created: 2026-10-01 12:15
updated: 2026-10-01 12:15
permalink: stack/sessions/stack-chronology-2026-10
tags:
- chronology
- codex
- migration
---

# Хроника работы над стеком — октябрь 2026

## 01.10 — перенос рабочего контура Claude → Codex

- Подключены `Codex-stack`, `stack-vault`, `tacticum-vault`; локальные и серверные роли, MCP,
  память ролей и конфигурация сведены.
- `roles.zsh` переведён на запуск Codex. Старые Claude-процессы в tmux штатно завершены.
- Созданы свежие серверные Codex-чаты ГД и трёх лидов AI PaaS с наследованием истории.
- Guard дополнен реестром native subagents, fail-closed для неизвестной роли, границами MCP,
  read-only ролями, защитой sentinel/stop-файлов, Docker-escape и A4 для implementer.
- Найдено, что hooks не подхватываются уже открытыми top-level чатами. Принято эксплуатационное
  правило: после изменения hooks роли запускаются только из нового top-level чата.
- Живой smoke нового top-level подтвердил deny обычного Bash и `apply_patch` у critic. На Linux
  свежая роль получила настоящий runtime `read-only`; для чтения добавлен строгий allowlist без
  вложенного sandbox, который внутри bwrap не может повторно примонтировать app-server socket.
- Implementer shell закрыт обязательным `:workspace` sandbox на точный linked worktree. Проверка
  показала deny записи вне worktree и успешную запись внутри.
- `stack-vault` объединён и синхронизирован на Mac, сервер и GitHub. Случайно попавшая `.serena`
  удалена из HEAD и добавлена в `.gitignore`.
- `tacticum-vault` объединён без force/reset: серверный снимок, локальные изменения и документы
  лидов сохранены. Объединённый `main` передан на сервер напрямую по SSH. Публикация в GitHub
  отложена: история содержит blob 713 МБ, который GitHub не примет обычным push.

