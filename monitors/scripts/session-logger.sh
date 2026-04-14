#!/bin/bash
LOG_FILE="${CLAUDE_PLUGIN_DATA}/monitor-test.log"
echo "[SESSION START] $(date '+%Y-%m-%d %H:%M:%S') | session: ${CLAUDE_SESSION_ID:-unknown}" >> "$LOG_FILE"
