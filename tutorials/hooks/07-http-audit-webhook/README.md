# 실습 7: 파일 편집 이벤트를 HTTP 웹훅으로 전송 (PostToolUse + http 타입)

## 학습 목표

- `http` 타입 훅이 `command`, `prompt` 타입과 어떻게 다른지 이해한다.
- 외부 HTTP 엔드포인트로 이벤트를 전송하는 방법을 익힌다.
- 셸 스크립트 없이 curl 없이 HTTP 요청을 보내는 패턴을 실습한다.

---

## 개념 설명

### 세 가지 훅 타입 비교

| 구분 | `command` | `prompt` | `http` |
|------|-----------|----------|--------|
| 동작 | 셸 스크립트 실행 | 텍스트를 Claude에 주입 | HTTP 요청 전송 |
| 차단 가능 | exit 2로 가능 | 불가 | 불가 |
| 외부 연동 | curl 등 직접 구현 | 없음 | 기본 제공 |
| 스크립트 필요 | 필요 | 불필요 | 불필요 |
| 사용 목적 | 검증, 차단 | 지시 주입 | 외부 시스템 연동 |

### http 타입 동작 흐름

```
Claude가 Write/Edit 도구 실행 완료
          ↓
  PostToolUse 훅 트리거
          ↓
  http 타입: 훅 이벤트 데이터를 HTTP POST로 전송
          ↓
  외부 서버에서 이벤트 수신 및 처리
```

Claude Code가 curl 없이 직접 HTTP 요청을 보낸다. `command` 타입에서 curl을 직접 호출하는 것보다 설정이 간결하다.

---

## 파일 구성

```
07-http-audit-webhook/
  README.md              ← 이 파일
  settings.json          ← http 타입 훅 설정
  hbn_webhook_server.py  ← 테스트용 로컬 웹훅 수신 서버
```

---

## 실습 순서

### 1단계: 웹훅 수신 서버 실행

별도 터미널에서 로컬 서버를 실행한다.

```bash
python3 tutorials/hooks/07-http-audit-webhook/hbn_webhook_server.py
```

출력:
```
웹훅 서버 시작: http://localhost:9000/hook
Claude Code에서 파일을 저장하면 이벤트가 표시됩니다. (Ctrl+C로 종료)
```

### 2단계: 설정 적용

`.claude/settings.json`의 `PostToolUse` 섹션에 아래 훅을 추가한다.

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "http",
          "url": "http://localhost:9000/hook",
          "method": "POST",
          "headers": {
            "Content-Type": "application/json",
            "X-Hook-Source": "claude-code"
          },
          "timeout": 5000
        }
      ]
    }
  ]
}
```

### 3단계: 동작 테스트

Claude Code에서 아무 파일이나 수정 요청을 한다.

```
간단한 hello.py 파일 만들어줘
```

**기대 결과 (서버 터미널):**
```
[2026-05-06 10:30:00] 훅 수신
  도구  : Write
  파일  : /path/to/hello.py
  전체  : {
    "tool_name": "Write",
    "tool_input": {
      "file_path": "...",
      "content": "..."
    }
  }
```

---

## HTTP 요청 형식

Claude Code가 전송하는 POST body는 `command` 타입 훅이 stdin으로 받는 것과 동일한 JSON이다.

```json
{
  "session_id": "...",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.py",
    "content": "..."
  }
}
```

---

## 활용 패턴

- **중앙 감사 서버:** 팀 전체 Claude Code 사용 이력을 한 서버에 수집
- **CI 트리거:** 파일 저장 시 자동으로 빌드/테스트 파이프라인 실행
- **Slack/Teams 연동:** command 타입 대신 http 타입으로 더 간결하게 알림 전송
- **데이터베이스 기록:** 외부 API를 통해 편집 이력을 DB에 저장

---

## 심화 과제

1. `hbn_webhook_server.py`를 수정해 수신한 이벤트를 파일(`audit.jsonl`)에 기록해보자.
2. `PreToolUse` 이벤트에도 `http` 훅을 추가해 명령 실행 전 외부 서버에서 허가를 받는 패턴을 구현해보자.
3. 실제 Slack Incoming Webhook URL을 `url`에 지정해 `command` 타입 없이 Slack 알림을 보내보자.
