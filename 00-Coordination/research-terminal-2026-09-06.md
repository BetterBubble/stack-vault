---
title: Ресерч — замена iTerm2 для стека параллельных сессий Claude Code
type: note
status: draft
created: 2026-09-06 00:50
updated: 2026-09-06 00:50
permalink: stack/coordination/research-terminal-2026-09-06
tags: [research, terminal]
---

# Замена iTerm2: терминал для множества параллельных сессий Claude Code

**Сценарий:** CLI-агенты в tmux на удалённом сервере + локальные сессии на маке.
**Боли:** iTerm2 лагает; при обрыве SSH раскладка ломается, перераскладку делает osascript-скрипт руками.
**Дата ресерча:** 2026-09-06. Всё ниже проверено веб-поиском по состоянию на конец 2026, не из головы. Что проверить не смог — помечено явно.

---

## 1. Ghostty — главный кандидат

**Зрелость/стабильность.** Актуальная стабильная версия — **1.3.1** (13.03.2026); 1.3.0 вышла 09.03.2026. Линия 1.2.x за осень 2025 закрыла критичный deadlock (1.2.3), утечку памяти (1.2.2) и проблемы titlebar. 1.3.1 добила «phantom mouse events» на macOS. Проект Митчелла Хашимото, развивается очень активно ([Releasebot: хроника релизов](https://releasebot.io/updates/ghostty), [релиз-ноуты 1.3.0](https://ghostty.org/docs/install/release-notes/1-3-0)).

**Производительность.** По обзорам 2026 — самый быстрый терминал на macOS: ~120fps скролл, задержка ввода <2ms, ~45MB RAM. Для сравнения: у iTerm2 замеряют ~12ms задержки ввода и видимый лаг при длинном выводе Claude Code ([DevToolReviews](https://www.devtoolreviews.com/reviews/ghostty-terminal-review-2026), [обзор терминалов под Claude Code](https://www.alexdunlop.com/writing/best-terminal-for-claude-code)).

**Скриптуемость раскладки — ключевое.** С 1.3.0 у Ghostty есть **нативный AppleScript-словарь**: создание окон/вкладок/сплитов (4 направления), отправка текста и клавиш, поиск терминала по рабочей директории, выполнение встроенных действий (`perform action`), broadcast команд ([доки AppleScript](https://ghostty.org/docs/features/applescript), [анонс Хашимото](https://x.com/mitchellh/status/2030063199052255504)). То есть наш osascript-скрипт раскладки **переносится почти один-в-один** — меняется только словарь с iTerm на Ghostty. Оговорка: в анонсе 1.3 фича называлась preview с возможными breaking changes в 1.4; текущая страница доков подаёт её как стабильную, включена по умолчанию (`macos-applescript`). Есть готовые примеры авто-раскладок ([пример: авто-раскладка проекта](https://samuellawrentz.com/blog/ghostty-applescript-project-terminal-layouts/), [Python-обёртка ghosttpy](https://github.com/DylanModesitt/ghosttpy)).

**Drag&drop.** Путь файла при перетаскивании вставляется (без завершающего пробела — мелкое трение, [обсуждение](https://github.com/ghostty-org/ghostty/discussions/5980)). Но **картинки в Claude Code drag&drop не работают** — CC полагается на iTerm-специфичный OSC 1337, Ghostty его не поддерживает; в iTerm2 работает, в Ghostty падает молча ([issue anthropics/claude-code#40218](https://github.com/anthropics/claude-code/issues/40218)). Вставка из буфера — отдельный вопрос, в issue не покрыт, не проверял вживую.

**Quirks с tmux.** Мелкие: поиск/скроллбар Ghostty может вытаскивать офф-скрин историю tmux ([issue #10227](https://github.com/ghostty-org/ghostty/issues/10227)); была регрессия с мышиным ресайзом бордеров tmux ([#9018](https://github.com/ghostty-org/ghostty/issues/9018)). Критичных несовместимостей не нашёл; связка Ghostty+tmux — самый популярный сетап под Claude Code в 2026 ([гайд](https://docs.bswen.com/blog/2026-03-12-best-terminal-setup-claude-code/), [ещё](https://andrewbaker.ninja/2026/06/05/ghostty-is-the-terminal-claude-code-deserves/)). Shift+Enter работает нативно, десктоп-уведомления пробрасываются в Notification Center без настройки.

**Чего нет:** tmux control mode (`-CC`, как в iTerm2) — только открытый feature request ([#1935](https://github.com/ghostty-org/ghostty/issues/1935)); своего мультиплексера/persistence нет — tmux остаётся обязательным.

## 2. WezTerm — мощный, но со звёздочками

**Конфиг на Lua**, встроенный мультиплексер и ssh-домены: клиент подключается по SSH, поднимает на сервере `wezterm-mux-server` и цепляется к нему — панели/вкладки живут на сервере и переживают обрыв, это архитектурная замена «ssh + tmux attach» ([доки multiplexing](https://wezterm.org/multiplexing.html), [SshDomain](https://wezterm.org/config/lua/SshDomain.html)).

**Но по фактам:**
- **Последний стабильный релиз — 20240203**, с февраля 2024 релизов нет; в трекере висит «Please keep creating stable releases» и «Next Release 2026-?» ([issue #7825](https://github.com/wezterm/wezterm/issues/7825), [releases](https://github.com/wezterm/wezterm/releases)). Проект жив (issues обрабатываются в сентябре 2026), но жить придётся на nightly.
- **Mux-сервер ненадёжен под нагрузкой:** зависает и перестаёт отвечать `wezterm cli`/attach ([#7692](https://github.com/wezterm/wezterm/issues/7692)), таймауты connect ([#6305](https://github.com/wezterm/wezterm/issues/6305)), краши при нескольких клиентах с разными размерами окна ([#2133](https://github.com/wezterm/wezterm/issues/2133)), закрытие одного окна роняет все окна того же remote ([#3633](https://github.com/wezterm/wezterm/issues/3633)). Для стека, где обрыв — регулярная боль, менять проверенный tmux на этот mux рискованно.
- Производительность на macOS исторически хуже Ghostty: framerate падает на больших окнах/4K ([#4292](https://github.com/wezterm/wezterm/issues/4292)).

**Скриптуемость** при этом отличная: `wezterm cli spawn / split-pane / send-text / activate-tab / adjust-pane-size` — полноценная программная раскладка без osascript ([wezterm cli](https://wezterm.org/cli/cli/index.html)).

## 3. kitty — зрелый максимум скриптуемости, минус нативность macOS

**Remote control:** `kitten @ launch --type=tab|window --cwd ...`, `kitten @ send-text`, layout-управление — самый зрелый API программного контроля из всех кандидатов, работает даже поверх SSH ([доки remote control](https://sw.kovidgoyal.net/kitty/remote-control/), [launch](https://github.com/kovidgoyal/kitty/blob/master/docs/launch.rst)). Плюс **session-файлы**: декларативно описываешь N вкладок/окон с командами — 0.43 добавил session management, 0.46 (2026) — momentum-скролл и tab reordering. Активно развивается.

**Минусы под наш сценарий:** нет нативных macOS-вкладок и нативного titlebar — UI реализован свой, «мак-нативность» хуже iTerm2 и Ghostty ([сравнение 2025](https://medium.com/@dynamicy/choosing-a-terminal-on-macos-2025-iterm2-vs-ghostty-vs-wezterm-vs-kitty-vs-alacritty-d6a5e42fd8b3), [kitty vs Ghostty 2026](https://moltamp.com/blog/kitty-vs-ghostty-2026/)). ssh kitten решает пробросы shell integration, но persistence не даёт — tmux всё равно нужен. Пользователь просил «красивый и современный» — kitty тут проигрывает Ghostty.

## 4. Warp — не подходит

AI-терминал с форс-логином, opt-out телеметрией и кредитной моделью; контекст команд уходит на их серверы. Главное: **Warp плохо работает внутри tmux, а tmux внутри Warp теряет фичи Warp** — вся его блочная модель несовместима с нашим сценарием «много tmux-сессий на сервере» ([Warp vs tmux](https://soloterm.com/warp-vs-tmux), [обзор 2026](https://pristren.com/blog/warp-terminal-review-2026/)). Память ~210MB idle против ~45MB у Ghostty. Agent mode дублирует то, что у нас уже делает Claude Code. Вычёркиваем.

## 5. Alacritty + tmux/zellij — минимализм

Alacritty быстрый, но без вкладок/сплитов/скриптуемости — вся раскладка уезжает в мультиплексер. Zellij активно развивается (0.45.0, 20.08.2026: nested sessions; 0.44.0, 03.2026: **remote sessions и CLI automation, web-client с resurrection**) ([zellij releases](https://zellij.dev/news/remote-sessions-windows-cli/), [web client](https://zellij.dev/documentation/web-client.html)) — любопытно как замена tmux в перспективе, но у нас на сервере уже tmux с обвязкой, менять оба слоя сразу — лишний риск. Не рекомендую как основное.

Отдельно всплыли: **cmux** — Mac-терминал на libghostty (YC, 03.2026), вкладки подсвечиваются, когда агент ждёт внимания — интересно понаблюдать; **Otty** — обещает восстановление workspace целиком. Оба молодые, в прод-стек рано.

---

## 6. Обрыв SSH: чтобы «оборвалось и само восстановилось»

Ключевая мысль: **раскладку и живость процессов уже сегодня держит серверный tmux — ломается только транспорт и локальное отображение.** Значит чинить надо транспорт, а не изобретать новую persistence.

| Решение | Как переживает обрыв | Минусы |
|---|---|---|
| **mosh + tmux attach** | UDP + State Sync Protocol: роуминг IP, сон мака, обрывы — сессия просто продолжается, «buttery smooth» на плохой сети | Нет своего скроллбека (отдаёт tmux — у нас и так так); UDP 60000-61000 бывает закрыт файрволами; последний релиз 1.4.0 (10.2022) — стабилен, но развитие заморожено ([mosh.org](https://mosh.org/), [сравнение](https://getmoshi.app/articles/fix-mosh-scrollback)) |
| **Eternal Terminal (et)** | TCP с буферами и авто-reconnect, drop-in замена ssh; **поддерживает tmux control mode** (важно, если останемся на iTerm2) | Нужен `etserver` на сервере; `brew install et` есть ([formulae](https://formulae.brew.sh/formula/et), [репо](https://github.com/MisterTea/EternalTerminal)) — релизы идут, но темп умеренный |
| **autossh** | Перезапускает ssh при разрыве; с `ssh <host> -t tmux attach` даёт авто-возврат в сессию | Реконнект = новое TCP-соединение: секунды паузы, при смене сети/IP хуже mosh |
| **ssh-домены WezTerm** | Панели живут в mux на сервере | См. выше — mux сыроват, не советую |
| **tmux поверх голого ssh** (сейчас) | Процессы живут, но attach руками + перераскладка | Текущая боль |

**Рекомендация по SSH:** **mosh поверх существующего tmux** — минимальное изменение (`mosh server -- tmux attach -t <сессия>` вместо `ssh`), обрывы исчезают как класс. Если UDP до сервера закрыт — **Eternal Terminal** тем же паттерном по TCP. autossh — запасной вариант нулевой стоимости. Проверить на месте: открыт ли UDP 60000-61000 до сервера — из ресерча это не узнать.

## 7. Программная раскладка — чем заменить osascript-скрипт

- **Ghostty:** тот же osascript, новый словарь: `tell application "Ghostty" → create window / create tab / split direction right / send text` + поиск терминала по cwd. Наименьшая переделка скрипта.
- **kitty:** `kitten @ launch --type=tab --cwd ... 'mosh server -- tmux attach -t lead1'` или session-файл целиком — чище osascript, но менее мак-нативно.
- **WezTerm:** `wezterm cli spawn/split-pane/send-text` — красиво, но на nightly-версиях.
- **Вариант «раскладка на сервере»:** держать раскладку не в терминале, а в tmux (окна/панели одной tmux-сессии) — тогда локально нужна одна вкладка на лида, и любой терминал подходит. Стоит рассмотреть параллельно: чем меньше раскладки на маке, тем меньше ломается при обрыве.

---

## Итог

**Топ-1: Ghostty 1.3.1 + серверный tmux + mosh.** Быстрее и нативнее всех на macOS, AppleScript закрывает раскладку (переписать словарь скрипта), tmux остаётся как есть, mosh убирает боль обрывов. Риски: AppleScript API может поменяться в 1.4 (следить); drag&drop картинок в Claude Code не работает (OSC 1337) — если картинки таскаются часто, это заметное трение.

**Топ-2: kitty.** Если AppleScript Ghostty окажется сырым — у kitty самый зрелый remote-control/session API, раскладка даже проще. Платим мак-нативностью внешнего вида.

**Миграция (Ghostty):** 1) поставить Ghostty, погонять неделю параллельно с iTerm2; 2) переписать osascript-скрипт на словарь Ghostty (по объёму — та же логика, другой словарь; пример-референс в источниках); 3) на сервер `etserver` или проверить UDP для mosh, обернуть подключения в `mosh/et ... tmux attach`; 4) знать, что теряем от iTerm2: tmux -CC и OSC 1337 (drag&drop картинок в CC).

**Не проверено вживую (честно):** реальную стабильность AppleScript Ghostty на 10+ вкладках; вставку картинок из буфера в CC под Ghostty; открыт ли UDP до нашего сервера; поведение mosh с ssh-manager MCP (он живёт отдельно от терминала — не должен пострадать, но не проверял).
