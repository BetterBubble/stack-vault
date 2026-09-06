---
title: Ресерч — телеграм-управление компанией агентов
type: note
status: draft
created: 2026-09-06 05:25
updated: 2026-09-06 05:25
permalink: stack/coordination/research-telegram-2026-09-06
tags: [research, telegram]
---

# Ресерч: телеграм-управление компанией агентов (2026-09-06)

Заказ: несколько каналов/ботов под разное, голосовые команды ГД, чат «ждёт меня», 3–5 чатов под задачи. Ниже — что уже сделало сообщество, что перенять, и вердикт по архитектуре.

## 1. Готовые проекты telegram ↔ Claude Code

### Живые и релевантные

**[alexei-led/ccgram](https://github.com/alexei-led/ccgram)** — самый близкий к нашей архитектуре проект. Python, 263★, 772+ коммита, активен. Мост Telegram ↔ tmux: **каждый forum-топик супергруппы = одно окно tmux**, команды идут через `send-keys`, агент остаётся в терминале («сессия — источник истины», SDK не оборачивается — ровно наша философия). Поддерживает Claude Code / Codex / Gemini / shell параллельно в разных топиках. Голос через Whisper на сервере. Allowlist по `ALLOWED_USERS` + привязка к группе. Очередь доставки длинных ответов с сохранением форматирования, защита от потопа (100+ ожидающих → подтверждение). Зависимость: `python-telegram-bot` (пиновая версия ради rate limiting). **Перенимать архитектуру топик↔tmux-окно; как зависимость тащить не обязательно — наш спроектированный мост делает то же самое проще.**

**[jsayubi/ccgram](https://github.com/jsayubi/ccgram)** (тёзка, другой проект) — TypeScript, 26★, маленький, но с самым ценным паттерном: **апрувы через inline-кнопки**. Хук `PermissionRequest` пишет pending-файл → в TG уходит сообщение с кнопками Allow/Deny/Always → тап пишет response-файл → хук читает и разблокирует Claude. Файловый IPC — точь-в-точь наш канал сигналов. Использует 13+ хуков (Stop, Notification, PreToolUse, SessionStart/End, SubagentStop…). Ядро — почти без зависимостей (только dotenv). **Перенимать паттерн pending/response-файлов для кнопочных решений («апрув · не апрув · на переделку» прямо с телефона).**

**[RichardAtCT/claude-code-telegram](https://github.com/RichardAtCT/claude-code-telegram)** — самый популярный (2.8k★, 419 форков, v1.3.0, активен). Полный комбайн: SDK+CLI, SQLite-сессии, `/repo`-переключение, directory sandboxing, аудит-лог, лимиты расходов, три уровня verbosity ответов, голос (Whisper / whisper.cpp / Voxtral). **Тащить как зависимость не стоит** — он оборачивает Claude Code сам и конфликтует с нашей tmux-компанией ролей; но перенять: allowlist + sandbox по каталогу, уровни verbosity (0 = только финальный ответ, 1 = + имена тулов, 2 = детально), учёт стоимости.

### Прочие (осмотрены, не тащим)
[terranc/claude-telegram-bot-bridge](https://github.com/terranc/claude-telegram-bot-bridge), [hanxiao/claudecode-telegram](https://github.com/hanxiao/claudecode-telegram), [RicardoAGL/claude-telegram-bridge](https://github.com/RicardoAGL/claude-telegram-bridge) (MCP-сервер для async-переписки), [andrueandersoncs/telegram-claude](https://github.com/andrueandersoncs/telegram-claude) — вариации тех же идей, меньше живости. `linux-do/claude-code-telegram` отдельно не найден — по описанию это форк/зеркало линии RichardAtCT.

## 2. Голос → команды агенту

Приём: Bot API отдаёт voice как OGG/Opus (`getFile` → скачать), конвертация `ffmpeg -i voice.ogg -ar 16000 -ac 1 wav` → STT. Паттерн отработан десятками ботов ([antirez/whisperbot](https://github.com/antirez/whisperbot) на whisper.cpp, [ckaytev/tgisper](https://github.com/ckaytev/tgisper) на faster-whisper, [soberhacker/telegram-speech-recognition-bot](https://github.com/soberhacker/telegram-speech-recognition-bot) — явно поддерживает русский).

STT на сервере для коротких русских команд:
- **faster-whisper (CTranslate2, int8) — рекомендация.** До 4× быстрее openai/whisper при той же точности. `small` — стандарт для голосовых интерфейсов: на современном CPU 10-секундная команда обрабатывается порядка ~1–3 с; помещается в 2 ГБ RAM. `medium` заметно точнее на русском, но на CPU это уже ~5–15 с на команду — терпимо для асинхронного пульта, но хуже для диалога.
- Русский у Whisper — категория «good» (WER ~10–20% на общем аудио; на коротких чётких командах — заметно лучше). Для командного словаря («статус», «апрув», «возьми задачу N») хватает `small`; сомнительные распознавания решать эхо-подтверждением: бот показывает текст, кнопка «да/переговорить».
- whisper.cpp тоже годен (работает даже на Pi 4 — [обсуждение](https://github.com/ggml-org/whisper.cpp/discussions/218)), но faster-whisper на python-сервере проще интегрировать в наш python-мост.
- Облако (OpenAI API) — быстрее и точнее, но голос ГД уходит наружу; для приватного пульта локальный STT честнее.

## 3. Мульти-бот vs топики vs каналы

**Главный вывод сообщества: один бот + forum topics в супергруппе, а не зоопарк ботов.**

- **Лимиты BotFather:** 20 ботов на аккаунт (40 с Premium) — [tginfo](https://github.com/tginfo/Telegram-Limits/issues/288). На 3–5 чатов хватит и ботов, но дело не в лимите.
- **Грабли мульти-бота в одной группе:** команды в любом топике триггерят ВСЕХ ботов группы ([issue](https://github.com/NousResearch/hermes-agent/issues/4622)); нужны уникальные токены и exclusive mentions. Несколько ботов = несколько токенов, несколько слушателей, несколько точек отказа.
- **Топики решают то же самое чище:** каждый топик — свой поток, свои закреплённые сообщения и **свои настройки уведомлений** (можно замьютить отчёты, оставив громким «ждёт меня»). Роутинг — по `message_thread_id` в апдейте; отправка в топик — тем же параметром в `sendMessage`. Без `message_thread_id` сообщение падает в General. Паттерн «топик = стабильный дом одной рабочей линии» описан у [MicroClaw](https://microclaw.ai/blog/telegram-topic-mode/) и реализован в ccgram (топик = tmux-окно).
- **Каналы** — для строго read-only потоков (лента отчётов/дайджестов), где не нужен ввод. Но топик с замьюченными уведомлениями даёт то же, не размазывая систему по двум сущностям. Канал оправдан один — если захочется публичной/семейной ленты статуса отдельно от пульта.
- **Rate limits Bot API:** ~1 msg/s в один чат, **20 msg/min в одну группу** (важно: все топики супергруппы делят этот лимит!), ~30 msg/s глобально; при 429 спать ровно `retry_after` ([python-telegram-bot wiki](https://github.com/python-telegram-bot/python-telegram-bot/wiki/Avoiding-flood-limits)). Вывод: сырой поток ход-логов в TG не лить — агрегировать в дайджесты; если потоков станет много, разнести шумные ленты во вторую группу или канал (у каждого свой лимит 20/мин).

## 4. Ответы агента в TG

- **Лимит 4096 символов.** Резать по границам строк ДО эскейпинга — MarkdownV2-эскейп раздувает текст на 4–8%, и чанк «ровно 4096» отлетает с MESSAGE_TOO_LONG ([md2tg](https://md2tg.projectstain.dev/guides/telegram-markdownv2-escaping), [gramiojs/split](https://github.com/gramiojs/split)).
- **MarkdownV2 — классическое минное поле:** 18 зарезервированных символов, эскейп контекстно-зависимый (в тексте — все 18, в `code` — только `` ` `` и `\`, в URL — только `)` и `\`); один глобальный escape ломает код-блоки. Готовое решение — [telegramify-markdown](https://github.com/sudoskys/telegramify-markdown) (python): конвертит обычный markdown в валидный MarkdownV2 и сам режет по 4096. **Брать его, не писать эскейпер руками.** Запасной вариант — слать plain text без parse_mode: некрасиво, но никогда не падает.
- Файлы/скриншоты: `sendDocument`/`sendPhoto` до 50 МБ через Bot API — для диффов, логов, скринов тестов. Длинный отчёт удобнее отправить файлом `.md` + короткая выжимка текстом.

## 5. Безопасность

- **Allowlist chat_id/user_id — обязателен, первый чек каждого апдейта.** Username подделывается, ID — нет. Все осмотренные мосты делают именно так (`ALLOWED_USERS`).
- **Утечка токена** = кто угодно читает апдейты и пишет от имени бота (у любого мостового бота внутри — путь к send-keys в tmux, то есть RCE на сервере). Токен — только в Keychain/env, не в git (наше правило и так это держит); при подозрении — `/revoke` в BotFather, токен меняется мгновенно. Плюс `deleteWebhook` при переходе на polling.
- Даже при утечке allowlist по ID спасает от исполнения команд — но не от чтения того, что бот УЖЕ отправил через getUpdates-очередь, поэтому секреты в сообщения не писать.
- Rate limits — см. §3; для нашего масштаба (один человек) не проблема, если не лить сырые логи.

## Вердикт-рекомендация

**Один бот. Одна супергруппа с forum topics. Слушатель — наш спроектированный python-мост на сервере (long-polling → tmux send-keys), расширенный, а не заменённый чужим проектом.**

Раскладка топиков (5–7, каждый со своим режимом уведомлений):

| Топик | Направление | Уведомления |
|---|---|---|
| **Ждёт меня** | агент → человек: разметка ГД, блокеры, «нужно решение» — с inline-кнопками апрува (паттерн jsayubi/ccgram: pending/response-файлы в канале сигналов) | громко |
| **Пульт ГД** | человек → агент: текст и голос; мост транскрибирует (faster-whisper small, int8, ru) и шлёт в tmux-окно ГД; эхо-подтверждение распознанного | громко (ответы) |
| **Отчёты** | агент → человек: дайджесты дня, итоги задач, ссылки на PR | мьют |
| **Задача-1…3** | двусторонние: топик = tmux-окно лида (ровно модель alexei-led/ccgram); создаются/архивируются по мере жизни задач | по вкусу |

Почему так: один токен и один слушатель (одна точка отказа и одна строка в Keychain), разные уведомления на топик закрывают «разные каналы для разного», роутинг тривиален (`message_thread_id` ↔ имя tmux-окна — одна таблица в конфиге моста). Мульти-бот не даёт ничего сверх этого, но умножает токены и грабли взаимных триггеров. Канал заводить только если появится желание read-only ленты вне пульта.

Что перенять поимённо: топик↔tmux-окно и очередь доставки (alexei-led/ccgram) · inline-апрувы через pending/response-файлы + хуки Stop/Notification (jsayubi/ccgram) · verbosity-уровни и sandbox по каталогу (RichardAtCT) · telegramify-markdown для вывода · faster-whisper small для голоса с эхо-подтверждением.

## Источники

- https://github.com/alexei-led/ccgram
- https://github.com/jsayubi/ccgram
- https://github.com/RichardAtCT/claude-code-telegram
- https://github.com/RicardoAGL/claude-telegram-bridge
- https://github.com/terranc/claude-telegram-bot-bridge
- https://github.com/antirez/whisperbot
- https://github.com/ckaytev/tgisper
- https://github.com/soberhacker/telegram-speech-recognition-bot
- https://github.com/SYSTRAN/faster-whisper
- https://smartscope.blog/en/generative-ai/foundations/whisper-local-cpu-implementation/
- https://github.com/ggml-org/whisper.cpp/discussions/218
- https://microclaw.ai/blog/telegram-topic-mode/
- https://github.com/NousResearch/hermes-agent/issues/4622
- https://github.com/tginfo/Telegram-Limits/issues/288
- https://github.com/python-telegram-bot/python-telegram-bot/wiki/Avoiding-flood-limits
- https://md2tg.projectstain.dev/guides/telegram-markdownv2-escaping
- https://github.com/sudoskys/telegramify-markdown
- https://github.com/gramiojs/split
