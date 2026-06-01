# 계약: 애플펜슬 입력 (Port / Adapter)

> 이 계약을 바꾸면 모든 스테이지에 영향. **변경 시 반드시 팀 합의 후 이 문서와 코드를 함께 갱신.**

## 왜 분리하나
"입력받는 로직"과 "받아서 쓰는 로직"을 나누면 (Ports & Adapters / 의존성 역전):
- 스테이지 개발자는 raw 펜슬 API를 몰라도 됨 → 게임 로직에 집중
- **시뮬레이터에서 목으로 개발** 가능 (펜슬프로 기능은 실기기 필요)
- 입력 출처(실기기/목)를 자유롭게 교체

## 3겹 구조
- **데이터 계약** `PencilState` — 게임이 읽는 "깨끗한 값"
- **생산자(교체 가능)** — `RealPencilFeeder`(실기기) **또는** `MockPencilFeeder`(슬라이더)
- **소비자** — 각 스테이지. `pencil.state`만 읽고 출처는 모름

## 코드

```swift
// PencilInput/PencilState.swift  ── 팀 공통 데이터 계약
import CoreGraphics

enum SqueezePhase { case none, began, changed, ended }

/// 게임 로직이 읽는 한 순간의 펜슬 상태. (raw UIKit 값이 아니라 '번역된' 값)
struct PencilState {
    var location: CGPoint? = nil       // 접촉 위치 (없으면 nil)
    var isTouching = false             // 캔버스 접촉 (Stage2)
    var isHovering = false             // 호버 조준 (Stage1)
    var pressure: Double = 0           // 0...1   (Stage1 드릴/끌)
    var tiltDegrees: Double = 0        // 0(수직)~90(수평) (Stage2)
    var barrelRollDegrees: Double = 0  // 0...360 (Stage2)
    var squeezePhase: SqueezePhase = .none  // (Stage3)
}
```

```swift
// PencilInput/PencilInput.swift  ── 소비자가 의존하는 단 하나의 관찰 대상
import Combine

final class PencilInput: ObservableObject {
    @Published var state = PencilState()   // 생산자가 갱신, 소비자가 읽음
}
```

- **소비자(스테이지)**: `@EnvironmentObject var pencil: PencilInput` → `pencil.state.tiltDegrees` *읽기만*.
- **생산자**: `RealPencilFeeder`(UIKit raw → 번역 후 `pencil.state`에 씀) / `MockPencilFeeder`(디버그 슬라이더로 씀).

## 채널별 매핑 (어느 스테이지가 무엇을 쓰나)

| `PencilState` 필드 | 출처(raw) | 사용 스테이지 |
| --- | --- | --- |
| `pressure` | `UITouch.force` | 1 (드릴/끌 세기) |
| `isHovering`,`location` | hover 좌표 | 1 (조준) |
| `tiltDegrees` | `90 - altitudeAngle` | 2 |
| `barrelRollDegrees` | `rollAngle` | 2 |
| `isTouching`,`location` | 터치 begin/move/end | 2 (자물쇠 캔버스) |
| `squeezePhase` | `UIPencilInteraction`(squeeze) | 3 |
| `location` | drag 좌표 | 3 (관 뚜껑 드래그) |

> 라디안/도 변환, 정규화(0~1) 같은 "번역"은 **전부 Adapter 안에서** 처리한다. 스테이지 코드는 깨끗한 값만 본다.
