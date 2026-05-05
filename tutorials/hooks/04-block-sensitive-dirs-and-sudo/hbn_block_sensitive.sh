#!/bin/bash
# PreToolUse 훅: 민감한 디렉터리 접근과 sudo 명령을 차단한다.
# stdin으로 JSON 형식의 툴 입력을 받는다.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null)

# /etc, /usr 디렉터리 접근 차단
if echo "$COMMAND" | grep -qE '(^|\s|/)(\/etc|\/usr)(\/|\s|$)'; then
    echo "🚫 차단됨: /etc 또는 /usr 디렉터리 접근은 허용되지 않습니다." >&2
    echo "   이유: 시스템 디렉터리는 정책상 접근이 제한됩니다." >&2
    exit 2
fi

# sudo 명령 차단
if echo "$COMMAND" | grep -qE '(^|\s)sudo(\s|$)'; then
    echo "🚫 차단됨: sudo 명령은 이 프로젝트에서 허용되지 않습니다." >&2
    echo "   이유: 권한 상승 명령은 보안 정책상 차단됩니다." >&2
    exit 2
fi

exit 0
