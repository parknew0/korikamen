# 컨벤션

## 커밋 메시지 (Conventional Commits)

형식: `type(scope): 제목` (제목 50자 내외, 마침표 X). 본문은 한 줄 띄우고 *왜/무엇*.

| type | 용도 |
| --- | --- |
| `feat` | 기능 추가 |
| `fix` | 버그 수정 |
| `docs` | 문서만 변경 |
| `refactor` | 동작 변화 없는 구조 개선 |
| `chore` | 빌드/설정/잡일 |

예시:
- `feat(stage2): Tilt 범위 3초 유지 판정 구현`
- `docs(stage1): 제한 시간 90초로 확정 반영`
- `refactor(core): GameManager 전환 로직 정리`

> 문서 커밋의 90%는 `docs(scope): 무엇을 했다` 한 줄로 충분. 큰 추가/구조 변경일 때만 본문에 요약 불릿.
> **스펙 주도**: 미결 사항이 결정으로 확정될 때마다 `docs(stageN): OOO 확정 반영` 커밋을 남겨 결정 이력을 추적.

## 브랜치
- 기능별 브랜치 후 PR. 예) `feat/stage2-tilt`, `docs/architecture`.

## 폴더 / 파일 네이밍
- 폴더: `Stages/StageN_역할` (예: `Stage1_Rock`).
- 뷰: `XxxView.swift`, 로직: `XxxViewModel.swift` / `XxxManager.swift`.
- 스테이지 전용 타입엔 `StageN` 접두 권장 (예: `Stage2GameManager`, `LockLevel`).

## 언어 통일
- 커밋 제목·문서는 **한글 통일**(명사형 종결: `~추가`, `~수정`). 코드 식별자는 영어.
