#!/bin/bash
# PreToolUse 훅: 위험한 Bash 명령어를 차단한다.
# stdin으로 JSON 형식의 툴 입력을 받는다.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('input', {}).get('command', ''))
" 2>/dev/null)

# rm -rf 패턴 차단
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\s'; then
    echo "🚫 차단됨: 'rm -rf' 명령은 이 프로젝트에서 허용되지 않습니다." >&2
    echo "   안전한 대안: 'rm -i' 또는 'trash' 명령을 사용하세요." >&2
    exit 2
fi

# chmod 777 패턴 차단
if echo "$COMMAND" | grep -qE 'chmod\s+777'; then
    echo "🚫 차단됨: 'chmod 777'은 보안상 허용되지 않습니다." >&2
    echo "   안전한 대안: 'chmod 755' 또는 'chmod 644'를 사용하세요." >&2
    exit 2
fi

exit 0
