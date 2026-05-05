#!/bin/bash
# Stop 훅: Claude Code 작업이 완료되면 macOS 알림을 표시한다.
# Stop 이벤트는 Claude가 응답을 완료했을 때 발생한다.

# stdin으로 전달된 JSON 데이터 읽기 (Stop 이벤트에서는 보통 비어 있음)
INPUT=$(cat)

TITLE="Claude Code"
MESSAGE="작업이 완료되었습니다 ✅"

# 로그 디렉터리 설정
LOG_DIR=".claude/logs"
mkdir -p "$LOG_DIR"

# macOS 알림 표시 (terminal-notifier: 알림센터 배너 보장)
NOTIFY_OUTPUT=$(terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound "Glass" -activate "com.apple.Terminal" 2>&1)
NOTIFY_EXIT=$?
echo "[$(date '+%Y-%m-%d %H:%M:%S')] terminal-notifier exit=$NOTIFY_EXIT output=$NOTIFY_OUTPUT" >> "$LOG_DIR/notify_debug.log"

# 작업 완료 시각 기록
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 작업 완료" >> "$LOG_DIR/completion_log.txt"

exit 0
