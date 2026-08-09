#!/usr/bin/env bash
# Проба: доктор MCP не печатает токен, лежащий в args stdio-сервера.
# Значение заведомо фальшивое — настоящих секретов проба не касается.
S="/private/tmp/claude-501/-Users-bubblemac-stack-vault/33ae1170-1bd6-4343-87a7-1618ab75e1c3/scratchpad"
SB="$S/mcpprobe"; rm -rf "$SB"; mkdir -p "$SB"
FAKE="sk-FAKEPROBE00000000000000000000"
cat > "$SB/.mcp.json" <<JSON
{"mcpServers":{"k4-argtoken":{"command":"cat","args":["--token","$FAKE"]}}}
JSON

out="$(MCP_DOCTOR_ROOTS="$SB" bash "$HOME/.claude/hooks/mcp-doctor.sh" --only k4-argtoken 2>&1)"

if printf '%s' "$out" | grep -q "FAKEPROBE"; then
  echo "ПРОВАЛ — значение из args напечатано:"
  printf '%s\n' "$out" | grep FAKEPROBE | head -2
else
  echo "ok — значение из args не попало в вывод"
  printf '%s\n' "$out" | grep -i "k4-argtoken" | head -2
fi
rm -rf "$SB"
