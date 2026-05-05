# 실습 5: sudo 명령 차단 시 Slack 알림 (PreToolUse + 외부 연동)

## 학습 목표

- 훅 스크립트에서 외부 서비스(Slack)를 호출하는 방법을 익힌다.
- `env` 설정으로 환경 변수를 훅에 전달하는 방법을 실습한다.
- 차단과 알림을 동시에 처리하는 패턴을 이해한다.

---

## 개념 설명

훅 스크립트는 단순한 차단을 넘어 **외부 서비스와 연동**할 수 있다.  
`sudo` 명령이 시도되면 실행을 차단하는 동시에 Slack으로 알림을 전송한다.

```
Claude가 sudo 명령 실행 요청
          ↓
    PreToolUse 훅 실행 (hbn_slack_notify.sh)
          ↓
    sudo 패턴 감지
          ↓
    Slack 웹훅으로 알림 전송 (curl)
          ↓
    exit 2 → 명령 차단
```

환경 변수 `SLACK_WEBHOOK_URL`은 `.claude/settings.json`의 `env` 섹션에 등록한다.  
훅 스크립트 실행 시 Claude Code가 해당 환경 변수를 자동으로 주입한다.

---

## 파일 구성

```
05-slack-notify-on-sudo/
  README.md            ← 이 파일
  settings.json        ← 훅 설정 (env 포함)
  hbn_slack_notify.sh  ← 훅 스크립트 본체
```

---

## 실습 순서

### 1단계: Slack Incoming Webhook URL 준비

1. Slack 워크스페이스에서 **Apps → Incoming Webhooks** 로 이동
2. 알림을 받을 채널을 선택하고 Webhook URL 생성
3. URL 형식: `https://hooks.slack.com/services/T.../B.../...`

### 2단계: 스크립트에 실행 권한 부여

```bash
chmod +x tutorials/hooks/05-slack-notify-on-sudo/hbn_slack_notify.sh
```

### 3단계: 환경 변수 등록

`.claude/settings.json`에 `env` 섹션을 추가하고 Webhook URL을 입력한다.

```json
{
  "env": {
    "SLACK_WEBHOOK_URL": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  },
  "hooks": { ... }
}
```

> **보안 주의:** Webhook URL은 민감한 정보다. `.gitignore`에 `.claude/settings.json`을 추가하거나 `settings.local.json`을 사용해 커밋에 포함되지 않도록 한다.

### 4단계: 프로젝트 설정에 훅 적용

`.claude/settings.json`의 `PreToolUse` 배열에 아래 항목을 추가한다.

```json
{
  "type": "command",
  "command": "bash tutorials/hooks/05-slack-notify-on-sudo/hbn_slack_notify.sh",
  "matcher": "Bash"
}
```

### 5단계: 동작 테스트

Claude Code에서 다음 메시지를 입력한다.

```
sudo ls /tmp 명령을 실행해줘
```

**기대 결과:**
- Claude가 sudo 명령 실행을 시도하면 훅이 차단
- Slack 채널에 아래와 같은 알림 메시지가 전송됨

```
🚨 [Claude Code] sudo 명령 차단됨
sudo ls /tmp
```

### 6단계: 스크립트 동작 직접 확인

터미널에서 아래 명령으로 스크립트를 직접 실행해 확인할 수 있다.

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"sudo ls /tmp"}}' \
  | SLACK_WEBHOOK_URL="https://hooks.slack.com/..." \
    bash tutorials/hooks/05-slack-notify-on-sudo/hbn_slack_notify.sh
echo "exit: $?"
```

---

## 동작 원리 상세

### 환경 변수 주입 흐름

```
.claude/settings.json
  "env": { "SLACK_WEBHOOK_URL": "https://..." }
          ↓
  Claude Code가 훅 실행 시 환경 변수로 주입
          ↓
  hbn_slack_notify.sh 내부에서 $SLACK_WEBHOOK_URL 사용 가능
```

### Slack 메시지 전송 (curl)

```bash
curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"text\":\"🚨 *[Claude Code] sudo 명령 차단됨*\n\`\`\`${COMMAND}\`\`\`\"}"
```

`SLACK_WEBHOOK_URL`이 비어 있으면 curl 호출을 건너뛰므로, URL 없이도 차단 기능은 정상 동작한다.

---

## 심화 과제

1. `/etc`, `/usr` 접근 시도에도 Slack 알림을 추가해보자.
2. 알림 메시지에 현재 시각과 프로젝트 경로(`$CLAUDE_PROJECT_DIR`)를 포함시켜보자.
3. Slack 대신 macOS 알림(`osascript`)과 함께 동시에 발송하도록 수정해보자.
