# 실습 2: 작업 완료 알림 훅 (Stop)

## 학습 목표

- `Stop` 이벤트 훅의 동작 시점을 이해한다.
- macOS 시스템 알림을 훅에서 표시하는 방법을 익힌다.
- 훅에서 로그 파일에 기록하는 패턴을 실습한다.

---

## 개념 설명

**Stop 훅**은 Claude가 응답을 **완료한 직후**에 호출된다.

```
Claude가 응답 완료
      ↓
  Stop 훅 실행
      ↓
  알림 표시 / 로그 기록 / 후처리 작업
```

Stop 이벤트는 다른 훅과 달리 **툴 matcher가 없다** — 항상 응답 완료 시점에 실행된다.

긴 작업을 Claude에게 맡기고 다른 일을 하다가, 완료되면 알림을 받고 싶을 때 유용하다.

---

## 파일 구성

```
02-completion-notification/
  README.md       ← 이 파일
  settings.json   ← 훅 설정
  hbn_notify.sh   ← 알림 + 로그 스크립트
```

---

## 실습 순서

### 1단계: 스크립트 내용 확인

```bash
cat tutorials/hooks/02-completion-notification/hbn_notify.sh
```

스크립트는 두 가지 동작을 수행한다.
1. `terminal-notifier`로 macOS 알림 센터 배너 표시
2. `~/.claude/completion_log.txt`에 완료 시각 기록

### 2단계: 스크립트에 실행 권한 부여

```bash
chmod +x tutorials/hooks/02-completion-notification/hbn_notify.sh
```

### 3단계: terminal-notifier 설치 확인

`terminal-notifier`가 설치되어 있는지 확인한다.

```bash
which terminal-notifier
```

설치되어 있지 않다면 Homebrew로 설치한다.

```bash
brew install terminal-notifier
```

다음 명령으로 직접 테스트한다.

```bash
terminal-notifier -title "테스트" -message "테스트 알림" -sound "Glass"
```

알림 센터 배너가 표시되면 준비 완료.

### 4단계: 훅 설정 파일 확인

```bash
cat tutorials/hooks/02-completion-notification/settings.json
```

```json
{
  "hooks": [
    {
      "event": "Stop",     ← Claude 응답 완료 시 발동
      "hooks": [
        {
          "type": "command",
          "command": "bash tutorials/hooks/02-completion-notification/hbn_notify.sh"
          // matcher 없음 — 모든 Stop 이벤트에 적용
        }
      ]
    }
  ]
}
```

### 5단계: 프로젝트 설정에 훅 적용

`.claude/settings.json`을 열고 `hooks` 배열에 아래 항목을 추가한다.

```json
{
  "event": "Stop",
  "hooks": [
    {
      "type": "command",
      "command": "bash tutorials/hooks/02-completion-notification/hbn_notify.sh"
    }
  ]
}
```

> **팁:** Claude Code `/hooks` 명령 → `Stop` 이벤트 선택 → 명령 입력

### 6단계: 동작 테스트

Claude Code에서 간단한 질문을 입력한다.

```
1부터 100까지 더하면 얼마야?
```

Claude가 응답을 완료하는 순간 macOS 알림 배너가 표시되어야 한다.

### 7단계: 로그 파일 확인

```bash
cat .claude/logs/completion_log.txt
```

응답이 완료될 때마다 타임스탬프가 기록된다.

```
[2026-05-05 14:32:10] 작업 완료
[2026-05-05 14:35:42] 작업 완료
```

---

## Stop 훅 활용 아이디어

| 활용 사례 | 구현 방법 |
|-----------|-----------|
| 슬랙 메시지 전송 | `curl`로 Slack Webhook 호출 |
| 음성 알림 | `say "작업 완료"` (macOS) |
| 완료 횟수 카운팅 | 파일에 카운터 증가 |
| 긴 작업 후 절전 방지 | `caffeinate -u` 리셋 |

---

## 심화 과제

1. `hbn_notify.sh`를 수정해 알림 메시지에 완료 시각을 포함시켜보자.
2. `say "Claude 작업 완료"` 명령을 추가해 음성 알림도 함께 받아보자.
3. 완료 로그가 100줄을 초과하면 오래된 항목을 자동 삭제하는 로직을 추가해보자.
