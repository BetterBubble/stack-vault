---
title: Как подключить телеграм к стеку — инструкция
type: note
status: archived
superseded-by: "[[area-telegram]]"
created: 2026-08-22 11:20
updated: 2026-08-22 11:20
permalink: stack/00-board/card-telegram-podklyuchenie-2026-08-22-1
tags:
- board
- telegram
- howto
---

# Как подключить телеграм к стеку

Замысел — [[Телеграм]]: зеркало (что читаю с телефона) и пульт (что отдаю обратно). Здесь —
как это собрать. **Две трубы ставятся отдельно и независимо**, и это главное решение
инструкции: исходящая делается за полчаса и почти без риска, входящая требует решения про
права. Начинать надо с исходящей — она одна уже закрывает большую часть пользы.

## Что уже есть и чего не хватает

**Пульт частично работает и без телеграма.** У ГД в статусной строке `/rc active` — это Remote
Control: сессия видна на claude.ai/code с телефона, туда можно писать. То есть «отдать задачу с
телефона» умеет и он. Чего Remote Control не умеет — **сам тебя дёрнуть**: он не пришлёт
уведомление, что задача закрыта или что появился блокер. Ровно эту дыру и закрывает телеграм.

Поэтому порядок такой: сначала пуши (то, чего нет нигде), потом — вход, если окажется мало.

## Шаг 1. Бот и токен

1. В телеграме написать `@BotFather` → `/newbot` → имя и username бота → он выдаст **токен**
   вида `1234567890:AAH...`.
2. Там же `/setprivacy` → **Enable** — бот не будет видеть чужие сообщения в группах.
3. Написать своему боту любое сообщение (иначе он не имеет права писать первым).
4. Узнать свой `chat_id`:
   `curl -s "https://api.telegram.org/bot<ТОКЕН>/getUpdates" | python3 -m json.tool | grep -m1 '"id"'`

## Шаг 2. Где хранить токен

**Значение токена в git не попадает никогда** — ни в личный репозиторий, ни в рабочий.

- **На маке:** Keychain через штатный `~/.claude/hooks/secret.sh` — так же, как остальные секреты.
- **На сервере:** Keychain нет, поэтому файл `~/.config/tg/env` с правами `600`:
  ```
  TG_TOKEN=1234567890:AAH...
  TG_CHAT=123456789
  ```
  `chmod 600 ~/.config/tg/env`. В vault кладётся только карта имён — что за токен и зачем,
  без значения.

## Шаг 3. Исходящая труба — пуши (делать первой)

Скрипт `~/claude-stack/tools/tg-send.sh` на сервере:

```bash
#!/usr/bin/env bash
# Отправка сообщения в телеграм. Токен из ~/.config/tg/env, в аргументах его нет никогда —
# иначе он утечёт в историю команд и в транскрипт агента.
set -uo pipefail
[ -r "$HOME/.config/tg/env" ] || { echo "tg-send: нет ~/.config/tg/env" >&2; exit 1; }
. "$HOME/.config/tg/env"
text="${1:?нужен текст}"
curl -sS -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
  -d chat_id="$TG_CHAT" -d parse_mode=Markdown --data-urlencode text="$text" \
  | grep -q '"ok":true' || { echo "tg-send: не отправлено" >&2; exit 1; }
```

Проверка: `bash ~/claude-stack/tools/tg-send.sh "проба"` — сообщение должно прийти.

**Кто и когда его зовёт.** По [[Телеграм]] пуши идут по событию, а не по расписанию, и только
четыре повода: задача закрыта и ждёт рук · появился блокер на Президенте · свод планов готов ·
итог ночной работы. Технически это одна строка в конце соответствующего действия лида либо хук
`Stop` у роли. **Ход работы и «начал задачу» не шлём** — канал, который шумит, перестают читать.

## Шаг 4. Входящая труба — пульт

Ключевое решение: **куда попадает текст из телеграма.** Два пути, и они не равноценны.

**Путь А — в живую сессию через tmux (рекомендую).** Роли уже живут окнами tmux на сервере,
и сообщение доставляется прямо в окно, будто ты сам напечатал:
`tmux send-keys -t company:lead-qa '<текст>' Enter`. Контекст сессии сохраняется, ответ агент
пишет туда же и при необходимости шлёт через `tg-send.sh`. Именно так уже работает `team`.

**Путь Б — headless `claude -p '<текст>'`.** Поднимает отдельный одноразовый вызов: у него нет
ни контекста задачи, ни истории. Годится для справок («что в статусе дня»), не годится для
работы.

Слушатель `~/claude-stack/tools/tg-listen.py` (long polling, ни домена, ни вебхуков не нужно):

```python
#!/usr/bin/env python3
# Мост телеграм → tmux. Принимает сообщения ТОЛЬКО от разрешённого chat_id и отправляет их
# в окно роли. Первое слово — адрес: «qa проверь стенд» уйдёт в company:lead-qa.
import os, time, json, subprocess, urllib.parse, urllib.request

env = {}
for line in open(os.path.expanduser("~/.config/tg/env")):
    if "=" in line:
        k, v = line.strip().split("=", 1)
        env[k] = v
TOKEN, CHAT = env["TG_TOKEN"], int(env["TG_CHAT"])
API = f"https://api.telegram.org/bot{TOKEN}"

def api(method, **params):
    url = f"{API}/{method}?" + urllib.parse.urlencode(params)
    with urllib.request.urlopen(url, timeout=70) as r:
        return json.load(r)

def send(text):
    api("sendMessage", chat_id=CHAT, text=text)

def windows():
    out = subprocess.run(["tmux", "list-windows", "-t", "company", "-F", "#{window_name}"],
                         capture_output=True, text=True).stdout.split()
    return out

offset = 0
while True:
    try:
        for u in api("getUpdates", offset=offset, timeout=60).get("result", []):
            offset = u["update_id"] + 1
            msg = u.get("message") or {}
            # чужие сообщения игнорируются молча: отвечать незнакомцу — значит подтвердить,
            # что бот живой и к нему есть смысл подбирать доступ
            if msg.get("chat", {}).get("id") != CHAT:
                continue
            text = (msg.get("text") or "").strip()
            if not text:
                continue
            if text in ("/who", "кто"):
                send("окна: " + ", ".join(windows())); continue
            addr, _, body = text.partition(" ")
            win = addr if addr.startswith("lead-") else f"lead-{addr}"
            if win not in windows() or not body:
                send(f"не понял адресата. Формат: <роль> <текст>. Есть: {', '.join(windows())}")
                continue
            subprocess.run(["tmux", "send-keys", "-t", f"company:{win}", body, "Enter"])
            send(f"→ {win}")
    except Exception as e:
        time.sleep(5)
```

## Шаг 5. Автозапуск на сервере

`~/.config/systemd/user/tg-listen.service`:

```ini
[Unit]
Description=Telegram -> tmux мост стека
After=network-online.target

[Service]
ExecStart=/usr/bin/python3 %h/claude-stack/tools/tg-listen.py
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now tg-listen
loginctl enable-linger alex        # чтобы жил без входа в систему
systemctl --user status tg-listen
```

## Чем это опасно и что с этим делать

**Бот, пишущий в окно роли, — это удалённое выполнение команд.** Роли подняты в
`bypassPermissions`, то есть текст из телеграма исполняется агентом без подтверждений. Кто
получил доступ к боту — получил сервер. Отсюда обязательное:

- **whitelist по `chat_id`** — в скрипте выше он единственный и жёсткий, чужие сообщения молча
  отбрасываются;
- **токен только в файле 600**, не в аргументах команд и не в git;
- **приватность бота включена** (`/setprivacy` → Enable);
- при утечке — `/revoke` у BotFather, старый токен умирает сразу;
- разумно ограничить, **что можно слать**: апрувы и задачи текстом — да, произвольные shell-команды
  через бота — нет.

Исходящая труба всех этих рисков не несёт вовсе: она только шлёт.

## Проверка, что работает

1. `bash tools/tg-send.sh "проба"` → сообщение пришло.
2. `/who` боту → список окон ролей.
3. `qa привет, ты на связи?` → текст появился в окне `company:lead-qa`, бот ответил `→ lead-qa`.
4. `systemctl --user restart tg-listen` → мост поднялся сам, без ручного запуска.

## Что осталось решить (из [[Телеграм]], не разобрано)

Нужен ли отдельный канал для срочного и тихий для сводок · идут ли пуши ночью · как отвечать на
конкретный пункт, когда ждущих несколько · шлём ли пуши от каждого лида или только сводкой.