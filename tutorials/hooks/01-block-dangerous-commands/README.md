# 실습 1: 위험한 명령어 차단 훅 (PreToolUse)

## 학습 목표

- `PreToolUse` 이벤트 훅의 동작 원리를 이해한다.
- 훅 스크립트가 stdin으로 툴 입력을 받는 방식을 익힌다.
- `exit 2`로 Claude의 명령 실행을 차단하는 방법을 실습한다.

---

## 개념 설명

**PreToolUse 훅**은 Claude가 특정 툴을 실행하기 **직전**에 호출된다.

```
Claude가 Bash 명령 실행 요청
        ↓
  PreToolUse 훅 실행
        ↓
  exit 0 → 명령 허용
  exit 2 → 명령 차단 (Claude에게 차단 이유 전달)
```

훅 스크립트는 **stdin**으로 다음과 같은 JSON을 받는다.

```json
{
  "tool_name": "Bash",
  "input": {
    "command": "rm -rf /tmp/test"
  }
}
```

---

## 파일 구성

```
01-block-dangerous-commands/
  README.md              ← 이 파일
  settings.json          ← 훅 설정 (프로젝트 .claude/settings.json에 복사)
  hbn_block_commands.sh  ← 훅 스크립트 본체
```

---

## 실습 순서

### 1단계: 훅 스크립트 내용 확인

`hbn_block_commands.sh`를 열어 어떤 패턴을 차단하는지 살펴본다.

```bash
cat tutorials/hooks/01-block-dangerous-commands/hbn_block_commands.sh
```

스크립트는 두 가지 패턴을 차단한다.
- `rm -rf` / `rm -fr` 계열 명령
- `chmod 777` 명령

### 2단계: 스크립트에 실행 권한 부여

```bash
chmod +x tutorials/hooks/01-block-dangerous-commands/hbn_block_commands.sh
```

### 3단계: 훅 설정 파일 확인

`settings.json`을 열어 훅이 어떻게 등록되어 있는지 확인한다.

```bash
cat tutorials/hooks/01-block-dangerous-commands/settings.json
```

```json
{
  "hooks": [
    {
      "event": "PreToolUse",       ← 툴 실행 직전에 발동
      "hooks": [
        {
          "type": "command",
          "command": "bash tutorials/hooks/01-block-dangerous-commands/hbn_block_commands.sh",
          "matcher": "Bash"        ← Bash 툴에만 적용
        }
      ]
    }
  ]
}
```

### 4단계: 프로젝트 설정에 훅 적용

`settings.json`의 내용을 프로젝트 `.claude/settings.json`에 병합한다.

```bash
cp .claude/settings.json .claude/settings.json.bak  # 기존 설정 백업
```

`.claude/settings.json`을 열고 `hooks` 배열에 아래 항목을 추가한다.

```json
{
  "event": "PreToolUse",
  "hooks": [
    {
      "type": "command",
      "command": "bash tutorials/hooks/01-block-dangerous-commands/hbn_block_commands.sh",
      "matcher": "Bash"
    }
  ]
}
```

> **팁:** Claude Code의 `/hooks` 명령을 사용하면 GUI로 훅을 추가할 수 있다.

### 5단계: 동작 테스트

Claude Code에서 다음 메시지를 입력해 차단이 작동하는지 확인한다.

**차단 테스트:**
```
rm -rf /tmp/test 명령을 실행해줘
```

Claude가 해당 명령을 실행하려 하면 훅이 가로채 "차단됨" 메시지와 함께 실행을 막는다.

**허용 테스트:**
```
ls -la 명령을 실행해줘
```

위험하지 않은 명령은 정상적으로 통과된다.

---

## 동작 원리 상세

| exit 코드 | 의미 |
|-----------|------|
| `exit 0` | 명령 허용, 정상 진행 |
| `exit 1` | 비정상 종료 (Claude에게 경고 표시, 명령은 실행됨) |
| `exit 2` | **명령 차단** — Claude가 해당 명령 실행을 중단함 |

`stderr`에 출력한 메시지는 차단 이유로 Claude에게 전달되어, Claude가 사용자에게 안내할 때 활용된다.

---

## 심화 과제

1. `curl` 명령으로 외부 IP로의 요청을 차단하는 패턴을 추가해보자.
2. 특정 디렉터리(`/etc`, `/usr`) 에 대한 `sudo` 명령을 차단해보자.
3. 차단 시 `stderr` 메시지를 변경해 어떻게 Claude 응답에 반영되는지 관찰해보자.
