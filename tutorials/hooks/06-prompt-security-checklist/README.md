# 실습 6: 코드 작성 후 보안 체크리스트 주입 (PostToolUse + prompt 타입)

## 학습 목표

- `prompt` 타입 훅이 `command` 타입과 어떻게 다른지 이해한다.
- `PostToolUse` 이벤트에서 Claude 컨텍스트에 텍스트를 주입하는 방법을 익힌다.
- 자동 보안 리뷰 패턴을 실습한다.

---

## 개념 설명

### command 타입 vs prompt 타입

| 구분 | `command` 타입 | `prompt` 타입 |
|------|---------------|--------------|
| 동작 | 셸 스크립트 실행 | 텍스트를 Claude 컨텍스트에 직접 주입 |
| 차단 가능 여부 | exit 2로 차단 가능 | 차단 불가 (알림/가이드 용도) |
| 동적 내용 | 스크립트 stdout으로 동적 생성 가능 | settings.json에 정적으로 정의 |
| 사용 목적 | 검증, 차단, 외부 연동 | 지시사항 추가, 컨텍스트 보강 |

### prompt 타입 동작 흐름

```
Claude가 Write/Edit 도구 실행 완료
          ↓
  PostToolUse 훅 트리거
          ↓
  prompt 타입: 지정된 텍스트를 Claude 대화에 주입
          ↓
  Claude가 주입된 지시사항을 읽고 보안 체크 수행
```

`command` 타입은 외부 프로세스를 실행하지만, `prompt` 타입은 **셸 스크립트 없이** settings.json에 정의된 텍스트를 Claude 컨텍스트에 바로 삽입한다.

---

## 파일 구성

```
06-prompt-security-checklist/
  README.md       ← 이 파일
  settings.json   ← prompt 타입 훅 설정
```

`command` 타입과 달리 셸 스크립트가 필요 없다.

---

## 실습 순서

### 1단계: 설정 적용

`.claude/settings.json`의 `PostToolUse` 섹션에 아래 훅을 추가한다.

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "prompt",
          "prompt": "방금 수정한 코드를 아래 보안 체크리스트 기준으로 검토하고, 문제가 있으면 즉시 수정하세요:\n1. SQL Injection: 사용자 입력이 쿼리에 직접 삽입되지 않는가?\n2. XSS: 출력 시 HTML 이스케이프 처리가 되어 있는가?\n3. 인증/인가: 민감한 엔드포인트에 권한 검사가 있는가?\n4. 하드코딩된 시크릿: 비밀번호나 API 키가 코드에 포함되어 있지 않은가?\n문제가 없으면 '보안 체크 완료'라고 짧게 답하세요."
        }
      ]
    }
  ]
}
```

### 2단계: 동작 테스트

Claude Code에서 다음 메시지를 입력한다.

```
간단한 로그인 함수를 login.py 파일로 만들어줘
```

**기대 결과:**
- Claude가 `login.py`를 작성한 직후 보안 체크리스트가 컨텍스트에 주입됨
- Claude가 자동으로 SQL Injection, 하드코딩된 비밀번호 등을 검토하고 결과를 응답함

---

## 동작 원리 상세

### prompt 주입 시점

```
PostToolUse 이벤트 발생 (Write/Edit 완료 후)
          ↓
Claude 응답 생성 전에 prompt 텍스트가 대화에 삽입됨
          ↓
Claude는 주입된 텍스트를 새 메시지처럼 인식하고 응답
```

### 활용 패턴

- **가이드라인 강제:** 코딩 컨벤션 체크를 매번 자동으로 수행
- **컨텍스트 보강:** 특정 도구 실행 후 관련 문서나 주의사항 주입
- **워크플로우 자동화:** 파일 작성 후 자동으로 다음 단계 지시

---

## command 타입과 함께 쓰기

`prompt` 타입은 `command` 타입과 함께 같은 이벤트에 등록할 수 있다.

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "python3 .claude/hooks/hbn-audit-logger.py"
        },
        {
          "type": "prompt",
          "prompt": "보안 체크리스트를 검토하세요."
        }
      ]
    }
  ]
}
```

실행 순서: `command` → `prompt` 순으로 처리된다.

---

## 심화 과제

1. `PreToolUse` 이벤트에 `prompt` 타입을 추가해 Bash 명령 실행 전 주의사항을 주입해보자.
2. 파일 확장자(`.py`, `.js`, `.sql`)에 따라 다른 체크리스트를 주입하려면 어떻게 해야 할까? (`command` 타입 stdout 활용)
3. `Stop` 이벤트에 `prompt` 타입을 추가해 작업 완료 후 항상 커밋 메시지 작성을 요청해보자.
