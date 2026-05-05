#!/bin/bash
# Stop 훅: Claude Code 작업이 완료되면 macOS 알림을 표시한다.
# Stop 이벤트는 Claude가 응답을 완료했을 때 발생한다.

# stdin으로 전달된 JSON 데이터 읽기 (Stop 이벤트에서는 보통 비어 있음)
INPUT=$(cat)

TITLE="Claude Code"
MESSAGE="작업이 완료되었습니다 ✅"

# macOS 알림 표시 (terminal-notifier: 알림센터 배너 보장)
terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound "Glass" -activate "com.apple.Terminal"

# 작업 완료 시각을 로그 파일에 기록 (훅은 프로젝트 루트에서 실행된다)
LOG_DIR=".claude/logs"
mkdir -p "$LOG_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 작업 완료" >> "$LOG_DIR/completion_log.txt"

exit 0
