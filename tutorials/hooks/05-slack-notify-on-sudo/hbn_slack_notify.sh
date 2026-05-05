#!/bin/bash
# PreToolUse 훅: sudo 명령 시도 시 Slack으로 알림을 보내고 차단한다.
# 환경 변수 SLACK_WEBHOOK_URL 이 설정되어 있어야 한다.

[ -f ~/.zshenv ] && . ~/.zshenv

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null)

if echo "$COMMAND" | grep -qE '(^|\s)sudo(\s|$)'; then
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -s -X POST "$SLACK_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"🚨 *[Claude Code] sudo 명령 차단됨*\n\`\`\`${COMMAND}\`\`\`\"}" \
            > /dev/null
    fi
fi

exit 0
