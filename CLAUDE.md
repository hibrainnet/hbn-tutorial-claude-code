# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

하이브레인넷 사내 Claude Code 실습 저장소. Claude Code의 확장 기능(Hooks, Skills, Settings)을 학습하기 위한 예제와 실습용 데이터셋을 제공한다.

## 저장소 구조

```
.claude/settings.json          # 프로젝트 활성 설정 (macOS 완료 알림 훅 포함)
data/                          # 실습용 데이터셋
  food_stores.csv              # 한국 식품 매장 DB (~49,000행)
  recruit_claude3-7.json       # 채용공고 구조화 데이터 (54건)
  ai-research.pdf              # AI 리서치 문서
  recruit_test.pdf             # 채용 테스트 문서
samples/claude/                # Claude Code 설정 예제 템플릿
  settings.json                # 위험한 rm 명령 차단 훅 예제
  hooks/block-rm.sh            # rm -rf 패턴 차단 Bash 훅
  hooks/security-validator.py  # Bash 명령 보안 검증 Python 훅
  hooks/settings.json          # 훅 설정 예제
  skills/SKILL.md              # explain-code 커스텀 스킬 예제
```

## 핵심 아키텍처

### Hooks
`samples/claude/hooks/`에 두 가지 PreToolUse 훅 예제가 있다.

- **block-rm.sh**: `rm -rf` 패턴을 정규식으로 감지해 exit 2로 차단
- **security-validator.py**: 루트/홈 디렉터리 재귀 삭제 등 위험 패턴을 JSON 응답으로 차단. exit 2는 작업 차단, exit 0은 허용

훅은 `.claude/settings.json`의 `hooks` 배열에 등록하고, `event: PreToolUse`와 `matcher: Bash`를 사용한다.

### Skills
`samples/claude/skills/SKILL.md`는 커스텀 스킬 포맷을 보여준다:
- YAML 프론트매터에 `name`과 `description` 정의
- 스킬 내용은 Claude가 따라야 할 지시사항으로 구성

### 설정 파일 구조
```json
{
  "hooks": [{
    "event": "PreToolUse | PostToolUse | Stop",
    "hooks": [{ "type": "command", "command": "..." }]
  }]
}
```

현재 활성 `.claude/settings.json`은 `Stop` 이벤트에서 macOS `osascript`로 "작업이 완료되었습니다" 알림을 표시한다.

## samples 활용법

`samples/claude/` 디렉터리 내용을 자신의 프로젝트 `.claude/` 디렉터리로 복사해 사용한다. 보안 훅은 그대로 사용할 수 있으며, 스킬은 `.claude/skills/` 디렉터리에 `.md` 파일로 추가하면 된다.
