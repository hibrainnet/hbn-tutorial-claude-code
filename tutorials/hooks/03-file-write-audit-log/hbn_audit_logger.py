#!/usr/bin/env python3
"""
PostToolUse 훅: Write / Edit 툴 사용 후 감사 로그를 기록한다.
stdout에 출력한 내용은 Claude에게 컨텍스트로 전달된다.
"""

import json
import os
import sys
from datetime import datetime

input_data = json.load(sys.stdin)
tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("input", {})

# 훅은 프로젝트 루트에서 실행되므로 프로젝트 상대 경로를 사용한다
LOG_DIR = ".claude/logs"
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "file_changes.log")

timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

if tool_name == "Write":
    file_path = tool_input.get("file_path", "(알 수 없음)")
    content = tool_input.get("content", "")
    entry = f"[{timestamp}] WRITE | {len(content):>7} bytes | {file_path}\n"
elif tool_name == "Edit":
    file_path = tool_input.get("file_path", "(알 수 없음)")
    old_string = tool_input.get("old_string", "")
    new_string = tool_input.get("new_string", "")
    entry = (
        f"[{timestamp}] EDIT  | "
        f"-{len(old_string)}b +{len(new_string)}b | {file_path}\n"
    )
else:
    sys.exit(0)

with open(LOG_FILE, "a", encoding="utf-8") as f:
    f.write(entry)

# stdout 출력은 Claude의 컨텍스트에 포함된다
print(f"[감사 로그] {entry.strip()}")

sys.exit(0)
