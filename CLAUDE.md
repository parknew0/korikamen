# C3 Korikamen — 프로젝트 가이드 (AI·팀 공통 진입점)

> 이 파일은 Claude Code 등 AI 도구가 자동으로 읽는 컨텍스트이자, 팀원 온보딩의 첫 문서입니다.
> 상세 내용은 아래 `docs/` 문서를 참고하세요. 결정이 바뀌면 **이 파일과 해당 문서를 같이** 갱신합니다.

## 한 줄 소개
애플펜슬프로 기능을 활용한 **2D 선형 서전시뮬레이션(방탈출형)**. 스토리 → 스테이지 1~3 → 엔딩.
이집트 투탕카멘 유물 도굴 컨셉이며, 스테이지마다 서로 다른 펜슬 인터랙션을 쓴다.

| 스테이지 | 컨셉 | 핵심 펜슬 입력 |
| --- | --- | --- |
| 1. 관 돌 부수기 | 돌 부수기(드릴/끌) | Pressure, Hover |
| 2. 관 자물쇠 따기 | 락픽 | Tilt, Barrel Roll |
| 3. 거미줄 제거 | 스퀴즈로 거미줄 제거 | Squeeze, Drag |

## 기술 스택
| 프레임워크 | 용도 |
| --- | --- |
| SwiftUI | 전체 UI, 상태 바인딩 |
| GameplayKit | 스테이지 전환 (`GKStateMachine` / `GKState`) |
| UIKit | 애플펜슬 입력 (`UIPencilInteraction` 스퀴즈 등) |
| SpriteKit | 거미줄/돌 레이어 연출 (SwiftUI에 `SpriteView`로 임베드) |
| Combine | 타이머·게이지 (`Timer.publish`) |

> 현재 레포는 Xcode "Game"(UIKit+SpriteKit) 템플릿 상태. SwiftUI App 라이프사이클로 전환 예정.

## 핵심 규칙 (AI·팀원 모두 준수)
1. **게임 로직은 `PencilState` 계약에만 의존** — raw 펜슬 API(`altitudeAngle`, `rollAngle`, `UIPencilInteraction` 등)를 스테이지 코드에서 직접 호출 금지. → `docs/contracts/pencil-input.md`
2. **스테이지별 판정 로직을 억지로 공통화하지 말 것** (Rule of Three). 겉모습(View)만 공통, 알맹이는 각자.
3. **폴더 경계 준수** — 각자 `Stages/StageN_*`만 수정 → 머지 충돌 방지.
4. **워킹 스켈레톤 우선** — 끝까지 도는 빈 껍데기부터. 빅뱅 통합 금지. → `docs/team-workflow.md`
5. 커밋 메시지는 `docs/conventions.md`의 규칙을 따른다.

## 문서 인덱스
- `docs/architecture.md` — 폴더 구조, 2층 설계(Core+Stages), 공통 vs 스테이지별
- `docs/team-workflow.md` — 업무 분장, 계약우선·스텁, 워킹스켈레톤, 빌드 순서
- `docs/contracts/pencil-input.md` — 애플펜슬 입력 계약 (Port/Adapter, 코드 포함)
- `docs/conventions.md` — 커밋/네이밍/폴더 컨벤션
- `docs/design/` — 스테이지별 기능 기획서 (`stage1_rock`, `stage3_spider`, …)
