# Claude Code Hooks 실습

Claude Code의 훅(Hook) 시스템을 단계별로 학습하는 실습 모음이다.

---

## Hooks란?

**훅**은 Claude Code의 특정 시점에 사용자 정의 스크립트를 자동으로 실행하는 확장 메커니즘이다.

Claude가 툴을 실행하거나 응답을 완료할 때, 훅을 통해 **차단, 검증, 로깅, 알림** 등의 동작을 삽입할 수 있다.

```
사용자 요청
    ↓
Claude가 동작 결정
    ↓
[PreToolUse 훅] ← 툴 실행 전 개입 가능
    ↓
툴 실행 (Bash / Write / Edit 등)
    ↓
[PostToolUse 훅] ← 툴 실행 후 후처리
    ↓
Claude 응답 완료
    ↓
[Stop 훅] ← 응답 완료 후 처리
```

---

## 이벤트 종류

| 이벤트 | 실행 시점 | 주요 용도 |
|--------|-----------|-----------|
| `PreToolUse` | 툴 실행 직전 | 위험 명령 차단, 입력 검증 |
| `PostToolUse` | 툴 실행 직후 | 감사 로그, 알림, 후처리 |
| `Stop` | Claude 응답 완료 후 | 완료 알림, 리포트 생성 |

---

## 훅 설정 구조

훅은 `.claude/settings.json`의 `hooks` 키에 등록한다.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/my_hook.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/notify.sh"
          }
        ]
      }
    ]
  }
}
```

### matcher

`matcher`는 훅을 적용할 툴 이름을 정규식으로 지정한다.

| 값 | 의미 |
|----|------|
| `"Bash"` | Bash 툴에만 적용 |
| `"Write\|Edit"` | Write 또는 Edit 툴에 적용 |
| `""` (빈 문자열) | 모든 툴(또는 이벤트)에 적용 |

---

## 훅 스크립트 동작 방식

### stdin 입력

`PreToolUse` / `PostToolUse` 훅은 실행 시 **stdin**으로 툴 정보를 JSON 형태로 받는다.

```json
{
  "tool_name": "Bash",
  "input": {
    "command": "rm -rf /tmp/test"
  }
}
```

`Stop` 훅은 stdin 입력이 없다.

### exit 코드

훅 스크립트의 종료 코드로 Claude의 동작을 제어한다.

| exit 코드 | 의미 |
|-----------|------|
| `0` | 정상 종료, 툴 실행 허용 |
| `1` | 오류 발생 (Claude에게 경고, 툴은 실행됨) |
| `2` | **툴 실행 차단** (PreToolUse에서만 유효) |

### stdout / stderr

| 출력 | 전달 대상 |
|------|-----------|
| `stdout` | Claude 컨텍스트에 포함 (Claude가 읽을 수 있음) |
| `stderr` | 차단 사유로 Claude에게 전달 |

---

## 실습 목록

| 번호 | 디렉터리 | 이벤트 | 핵심 개념 |
|------|----------|--------|-----------|
| 01 | `01-block-dangerous-commands/` | `PreToolUse` | `exit 2`로 위험 명령 차단 |
| 02 | `02-completion-notification/` | `Stop` | `terminal-notifier`로 완료 알림 |
| 03 | `03-file-write-audit-log/` | `PostToolUse` | 파일 변경 감사 로그 + stdout → Claude 컨텍스트 |

---

## 빠른 시작

### 1. 원하는 실습 디렉터리의 README를 읽는다

```bash
cat tutorials/hooks/01-block-dangerous-commands/README.md
```

### 2. 훅 스크립트에 실행 권한을 부여한다

```bash
chmod +x tutorials/hooks/01-block-dangerous-commands/hbn_block_commands.sh
```

### 3. `.claude/settings.json`에 훅 설정을 추가한다

각 실습 디렉터리의 `settings.json`을 참고해 프로젝트 설정에 병합한다.

### 4. Claude Code에서 테스트한다

Claude에게 해당 시나리오를 요청하고 훅이 동작하는지 확인한다.

---

## 팁

- `/hooks` 명령으로 GUI에서 훅을 추가할 수 있다.
- 훅 스크립트는 **프로젝트 루트**를 현재 디렉터리로 실행된다.
- 여러 훅을 같은 이벤트에 등록하면 **순서대로** 실행된다.
- `PreToolUse`에서 `exit 2`를 반환하면 이후 훅은 실행되지 않는다.
