#!/bin/bash
set -euo pipefail

cmd=(claude --dangerously-skip-permissions "$@")

if [ "${AGENT_SANDBOX:-1}" != "0" ]; then
  cmd=(srt --settings /etc/claude-code/srt-settings.json -- "${cmd[@]}")
fi

exec "${cmd[@]}"
