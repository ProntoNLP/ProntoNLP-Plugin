#!/bin/bash
LOG_FILE="${CLAUDE_PLUGIN_DATA}/monitor-test.log"
echo "[SKILL INVOKE]  $(date '+%Y-%m-%d %H:%M:%S') | skill: ${CLAUDE_SKILL_NAME:-unknown} | session: ${CLAUDE_SESSION_ID:-unknown}" >> "$LOG_FILE"
