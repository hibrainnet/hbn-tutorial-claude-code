# 실습 3: 파일 쓰기 감사 로그 훅 (PostToolUse)

## 학습 목표

- `PostToolUse` 이벤트 훅의 동작 시점을 이해한다.
- 훅 스크립트에서 `tool_name`과 `input` 데이터를 파싱하는 방법을 익힌다.
- 훅의 **stdout 출력이 Claude 컨텍스트에 포함**되는 동작을 실습한다.
- `matcher`로 특정 툴에만 훅을 적용하는 방법을 배운다.

---

## 개념 설명

**PostToolUse 훅**은 Claude가 툴 실행을 **완료한 직후**에 호출된다.

```
Claude가 Write / Edit 툴 실행
           ↓
     툴 실행 완료
           ↓
   PostToolUse 훅 실행
           ↓
   로그 기록 + stdout 출력
           ↓
   stdout 내용 → Claude 컨텍스트에 포함
```

PreToolUse와 달리 이미 실행된 작업이므로 차단(`exit 2`)은 의미가 없다.  
대신 **후처리, 로깅, 알림, 검증** 등에 활용한다.

훅 스크립트가 `stdout`에 출력한 내용은 Claude에게 **컨텍스트로 전달**된다.  
이를 활용해 "방금 이 파일을 수정했음"을 Claude가 인식하게 만들 수 있다.

---

## 파일 구성

```
03-file-write-audit-log/
  README.md            ← 이 파일
  settings.json        ← 훅 설정
  hbn_audit_logger.py  ← Python 감사 로그 스크립트
```

---

## 실습 순서

### 1단계: 스크립트 내용 확인

```bash
cat tutorials/hooks/03-file-write-audit-log/hbn_audit_logger.py
```

스크립트가 처리하는 두 가지 케이스를 확인한다.
- `Write` 툴: 파일 경로와 쓰기 바이트 수를 로그에 기록
- `Edit` 툴: 파일 경로와 변경 전/후 글자 수를 로그에 기록

### 2단계: 훅에 전달되는 JSON 구조 파악

PostToolUse 훅이 stdin으로 받는 JSON 구조는 다음과 같다.

**Write 툴 실행 시:**
```json
{
  "tool_name": "Write",
  "input": {
    "file_path": "/path/to/file.py",
    "content": "파일 전체 내용..."
  },
  "output": "File created successfully."
}
```

**Edit 툴 실행 시:**
```json
{
  "tool_name": "Edit",
  "input": {
    "file_path": "/path/to/file.py",
    "old_string": "기존 텍스트",
    "new_string": "새 텍스트"
  },
  "output": "File edited successfully."
}
```

### 3단계: 훅 설정 파일 확인

```bash
cat tutorials/hooks/03-file-write-audit-log/settings.json
```

```json
{
  "hooks": [
    {
      "event": "PostToolUse",          ← 툴 실행 완료 후 발동
      "hooks": [
        {
          "type": "command",
          "command": "python3 tutorials/hooks/03-file-write-audit-log/hbn_audit_logger.py",
          "matcher": "Write|Edit"      ← Write 또는 Edit 툴에만 적용
        }
      ]
    }
  ]
}
```

`matcher`는 정규식이므로 `Write|Edit`은 두 툴 이름 중 하나와 매칭된다.

### 4단계: 프로젝트 설정에 훅 적용

`.claude/settings.json`을 열고 `hooks` 배열에 아래 항목을 추가한다.

```json
{
  "event": "PostToolUse",
  "hooks": [
    {
      "type": "command",
      "command": "python3 tutorials/hooks/03-file-write-audit-log/hbn_audit_logger.py",
      "matcher": "Write|Edit"
    }
  ]
}
```

### 5단계: 동작 테스트

Claude Code에서 파일을 생성하거나 수정하도록 요청한다.

**테스트 메시지 예시:**
```
test_output.txt 파일을 만들고 "Hello, Hooks!" 라고 써줘
```

Claude가 `Write` 툴로 파일을 생성하면 훅이 실행된다.

### 6단계: 로그 파일 확인

```bash
cat .claude/logs/file_changes.log
```

다음과 같은 형식으로 기록된다.

```
[2026-05-05 14:20:31] WRITE |      15 bytes | /Users/user/project/test_output.txt
[2026-05-05 14:25:10] EDIT  | -12b +18b | /Users/user/project/test_output.txt
```

### 7단계: stdout → Claude 컨텍스트 확인

Claude의 응답에서 감사 로그 내용이 인식되는지 관찰한다.

`hbn_audit_logger.py`는 `print()`로 로그 내용을 stdout에도 출력한다.  
이 내용이 Claude에게 전달되어 "방금 이 파일을 수정했음"을 인식할 수 있다.

다음 메시지로 확인해보자:
```
방금 어떤 파일에 무엇을 기록했는지 알고 있어?
```

---

## 이벤트별 훅 비교 정리

| 이벤트 | 실행 시점 | 주요 용도 | exit 2 효과 |
|--------|-----------|-----------|-------------|
| `PreToolUse` | 툴 실행 전 | 차단, 입력 검증 | 실행 중단 |
| `PostToolUse` | 툴 실행 후 | 로깅, 알림, 후처리 | 효과 없음 |
| `Stop` | 응답 완료 후 | 완료 알림, 후처리 | 해당 없음 |

---

## 심화 과제

1. `hbn_audit_logger.py`를 수정해 `Read` 툴도 감사 로그에 포함시켜보자.
2. 하루에 수정된 파일 목록만 출력하는 스크립트를 따로 만들어보자.
3. 특정 파일(예: `.env`, `*.pem`)이 Write될 때만 경고 메시지를 stdout에 출력해, Claude가 인식하도록 만들어보자.
