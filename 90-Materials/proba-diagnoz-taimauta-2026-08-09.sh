#!/usr/bin/env bash
# Проба: доктор различает «порт закрыт» и «сервер молчит».
# ВАЖНО про фикстуру: подробный диагноз доктор печатает только для ОДОБРЕННЫХ серверов —
# первая версия пробы этого не учла, сервер числился «не одобрен», и обе ветки молчали.
# Поэтому подменяем HOME и кладём туда settings.json с enabledMcpjsonServers.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
SB="$S/mcptime2"; rm -rf "$SB"; mkdir -p "$SB/home/.claude" "$SB/proj"
printf '{"enabledMcpjsonServers":["k4-slow","k4-dead"]}' > "$SB/home/.claude/settings.json"
PORT=47631

python3 - "$PORT" <<'PY' &
import socket, sys, time
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", int(sys.argv[1]))); s.listen(5)
end = time.time() + 60
while time.time() < end:
    try:
        s.settimeout(2); c, _ = s.accept()      # приняли и молчим — «повисший» сервер
    except Exception:
        pass
PY
SRV=$!
trap 'kill $SRV 2>/dev/null' EXIT
sleep 1

echo "── повисший сервер: порт открыт, ответа нет ──"
printf '{"mcpServers":{"k4-slow":{"type":"http","url":"http://127.0.0.1:%s/mcp"}}}' "$PORT" > "$SB/proj/.mcp.json"
out="$(HOME="$SB/home" MCP_DOCTOR_ROOTS="$SB/proj" bash "$HOME/.claude/hooks/mcp-doctor.sh" --only k4-slow 2>&1)"
printf '%s\n' "$out" | grep -E "Причина|curl:" | head -3 | sed 's/^/  /'
printf '%s' "$out" | grep -q "порт ОТКРЫТ" && echo "  ok — таймаут назван таймаутом" \
                                           || echo "  ПРОВАЛ — повисший сервер объявлен незапущенным"

echo "── контроль: реально закрытый порт ──"
printf '{"mcpServers":{"k4-dead":{"type":"http","url":"http://127.0.0.1:47999/mcp"}}}' > "$SB/proj/.mcp.json"
out2="$(HOME="$SB/home" MCP_DOCTOR_ROOTS="$SB/proj" bash "$HOME/.claude/hooks/mcp-doctor.sh" --only k4-dead 2>&1)"
printf '%s\n' "$out2" | grep -E "Причина" | head -2 | sed 's/^/  /'
printf '%s' "$out2" | grep -q "порт закрыт" && echo "  ok — закрытый порт назван закрытым" \
                                            || echo "  ПРОВАЛ — диагноз потерян"
rm -rf "$SB"
