# 실습 4: 민감한 디렉터리 접근 및 sudo 차단 훅 (PreToolUse)

## 학습 목표

- 특정 디렉터리(`/etc`, `/usr`)에 대한 모든 명령을 차단하는 훅을 작성한다.
- `sudo` 명령 전체를 차단하는 패턴을 익힌다.
- 정규식으로 여러 패턴을 조합하는 방법을 실습한다.

---

## 개념 설명

시스템 디렉터리(`/etc`, `/usr`)나 권한 상승 명령(`sudo`)은 잘못 사용하면 시스템 전체에 영향을 줄 수 있다.  
PreToolUse 훅으로 Claude가 이런 명령을 실행하기 전에 차단할 수 있다.

```
Claude가 Bash 명령 실행 요청
        ↓
  PreToolUse 훅 실행 (hbn_block_sensitive.sh)
        ↓
  /etc, /usr 접근 감지? → exit 2 (차단)
  sudo 명령 감지?       → exit 2 (차단)
        ↓
  해당 없음 → exit 0 (허용)
```

---

## 파일 구성

```
04-block-sensitive-dirs-and-sudo/
  README.md               ← 이 파일
  settings.json           ← 훅 설정
  hbn_block_sensitive.sh  ← 훅 스크립트 본체
```

---

## 실습 순서

### 1단계: 스크립트 내용 확인

```bash
cat tutorials/hooks/04-block-sensitive-dirs-and-sudo/hbn_block_sensitive.sh
```

스크립트는 두 가지 패턴을 차단한다.

| 패턴 | 예시 | 차단 이유 |
|------|------|-----------|
| `/etc`, `/usr` 경로 포함 | `cat /etc/passwd`, `ls /usr/bin` | 시스템 설정 디렉터리 보호 |
| `sudo` 명령 | `sudo apt install`, `sudo chmod` | 권한 상승 차단 |

### 2단계: 스크립트에 실행 권한 부여

```bash
chmod +x tutorials/hooks/04-block-sensitive-dirs-and-sudo/hbn_block_sensitive.sh
```

### 3단계: 훅 설정 파일 확인

```bash
cat tutorials/hooks/04-block-sensitive-dirs-and-sudo/settings.json
```

```json
{
  "hooks": [
    {
      "event": "PreToolUse",
      "hooks": [
        {
          "type": "command",
          "command": "bash tutorials/hooks/04-block-sensitive-dirs-and-sudo/hbn_block_sensitive.sh",
          "matcher": "Bash"
        }
      ]
    }
  ]
}
```

### 4단계: 프로젝트 설정에 훅 적용

`.claude/settings.json`의 `PreToolUse` 배열에 아래 항목을 추가한다.

```json
{
  "type": "command",
  "command": "bash tutorials/hooks/04-block-sensitive-dirs-and-sudo/hbn_block_sensitive.sh",
  "matcher": "Bash"
}
```

> **팁:** Claude Code의 `/hooks` 명령을 사용하면 GUI로 훅을 추가할 수 있다.

### 5단계: 차단 테스트

Claude Code에서 다음 메시지를 입력해 차단이 작동하는지 확인한다.

**디렉터리 접근 차단 테스트:**
```
cat /etc/hosts 내용을 보여줘
```
```
ls /usr/bin 목록을 출력해줘
```

**sudo 차단 테스트:**
```
sudo ls /tmp 명령을 실행해줘
```

**허용 테스트 (차단되지 않아야 함):**
```
ls -la /tmp 명령을 실행해줘
```

### 6단계: stderr 메시지 확인

차단 시 Claude가 응답에 어떻게 차단 이유를 반영하는지 관찰한다.  
`hbn_block_sensitive.sh`의 `stderr` 메시지를 바꿔보며 동작 변화를 확인해보자.

---

## 동작 원리 상세

훅 스크립트가 stdin으로 받는 JSON 구조:

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "cat /etc/passwd"
  }
}
```

스크립트는 `tool_input.command` 값을 파싱해 정규식으로 패턴을 검사한다.

| exit 코드 | 의미 |
|-----------|------|
| `exit 0` | 명령 허용 |
| `exit 2` | **명령 차단** — stderr 메시지가 Claude에게 전달됨 |

---

## 심화 과제

1. `/home` 디렉터리도 차단 목록에 추가해보자.
2. `sudo` 중에서도 `sudo -l`(권한 조회)은 허용하도록 예외 처리를 추가해보자.
3. 차단된 명령을 별도 로그 파일에 기록하는 기능을 추가해보자.
