# 스테이지 3 : 관 열기 & 거미줄 제거

> **기능 기획서** · 이집트 투탕카멘 유물 도굴 게임

제한 시간 안에 관(棺)을 열고, 그 안에 있는 코리카멘을 감싼 거미줄을 제거하는 스테이지. Apple Pencil Pro의 **스퀴즈** 기능으로 바람을 불어 거미줄을 걷어내되, 매번 바뀌는 **랜덤 게이지 범위**에 정확히 맞춰야 하는 긴장감이 핵심이다.

---

## 🍎 완료 판단 기준

- [ ] 관 뚜껑을 드래그해서 여는 인터랙션을 이해할 수 있다
- [ ] 스퀴즈로 바람을 불어 거미줄을 제거하는 기믹을 이해할 수 있다
- [ ] 게이지 범위가 매번 바뀐다는 걸 플레이어가 직관적으로 알 수 있다
- [ ] 클리어 조건(5번 성공 + 시간 안에)을 플레이어가 직관적으로 알 수 있다
- [ ] 실패가 언제 어떻게 일어나는지 알 수 있다

---

## 1. 씬 구성

스테이지 3은 두 개의 씬으로 구성된다.

| 씬 | 내용 | 핵심 인터랙션 |
|----|------|--------------|
| **Scene 1** | 관 열기 | 펜슬로 관 뚜껑을 왼→오 드래그 |
| **Scene 2** | 거미줄 제거 | 스퀴즈로 바람을 불어 거미줄 제거 |

- 제한 시간 **90초**는 Scene 1 시작과 동시에 카운트
- 시간은 두 씬 전체에 걸쳐 공유됨

---

## 2. Scene 1 — 관 열기

### 인터랙션

- Apple Pencil Pro로 관 뚜껑을 **왼 → 오** 방향으로 드래그
- 관 너비의 **50% 이상** 밀면 자동으로 완전히 열림
- 50% 미만에서 손을 떼면 스프링처럼 닫힘 (재시도)

### 관 구성

- 관은 **3D** 로 렌더링 (애셋 미확정)
- 관이 열리면 안쪽은 검은색으로만 표현
- 완전히 열린 후 코리카멘의 모습이 등장 → Scene 2 전환

---

## 3. Scene 2 — 스퀴즈로 거미줄 제거

### 인터랙션

- 스퀴즈를 **꾹 누르면** 게이지가 증가 (50ms 당 +2.75%)
- 손을 떼는 순간 **그 때의 게이지 값**으로 성공/실패 판정
- 성공하면 코리카멘의 거미줄 레이어 1겹 제거
- **5번 성공** 시 스테이지 클리어

### 랜덤 게이지 범위 기믹

매 성공마다 다음 성공 범위가 랜덤으로 바뀐다.

| 라운드 | 범위 |
|--------|------|
| 1라운드 (초기) | 75 ~ 85% 고정 |
| 2라운드~ 5라운드| 랜덤 범위로 변경 |

- 범위가 좁고 위치가 극단적으로 바뀔 수 있어 긴장감 유지
- 실패 시 범위는 유지됨 (게이지만 리셋)

### 거미줄 레이어 구조

- 코리카멘 + 거미줄은 **2D** (애셋 미확정)
- 총 5겹, 성공할 때마다 1겹씩 제거

```
webLayerIndex = 5  → 거미줄 5겹 (초기)
      ↓ 1번 성공  → 4겹 남음
      ↓ 2번 성공  → 3겹 남음
           ...
      ↓ 5번 성공  → 전부 제거 → 클리어
```

---

## 4. 플레이 흐름

1. **스테이지 시작 → 타이머 90초 시작**
2. **Scene 1 : 관 뚜껑 드래그**
   - 왼→오 드래그, 50% 이상 → 자동으로 완전히 열림
   - 50% 미만 → 스프링 복귀, 재시도
3. **Scene 2 : 스퀴즈로 거미줄 제거**
   - 게이지 범위 확인 → 스퀴즈 꾹 누르기 → 타이밍 맞춰 손 떼기
   - 성공 → 거미줄 1겹 제거 → 다음 범위 랜덤 변경
   - 실패 → 게이지 리셋, 범위 유지 → 재시도
4. **5번 성공 → 시간 초과 여부 확인**
   - 시간 남음 → 스테이지 3 클리어 → 게임 엔딩 뷰로 이동
   - 시간 초과 → 스테이지 실패 

---

## 5. 플로우차트


```mermaid
flowchart TD
    START([● START]) --> startTimer["startTimer()\n90초 카운트 시작"]

    %% ─────────────────────────────
    %% SCENE 1 — 관 열기
    %% ─────────────────────────────
    startTimer --> S1(["SCENE 1 — 관 열기"])
    S1 --> TC1{"시간 초과?"}

    TC1 -->|"time remaining <= 0"| FAIL_S1(["🔴 실패화면으로 이동"])
    TC1 -->|"time remaining > 0"| DRAG["애플 펜슬로 관 뚜껑을\n왼 → 오 방향으로 드래그"]

    DRAG --> RATIO{"드래그 후 손을 뗐을 때\n이동비율은 어떤가?"}

    RATIO -->|"< 50%  관 기준"| SNAP["스프링 복귀 + 관 닫힘"]
    RATIO -->|">= 50%  관 기준"| OPEN["관 열림\n다음 Scene으로 이동"]

    SNAP --> TC1_RETRY{"시간 초과?"}
    TC1_RETRY -->|"time remaining <= 0"| FAIL_S1
    TC1_RETRY -->|"time remaining > 0"| DRAG

    %% ─────────────────────────────
    %% SCENE 2 — 거미줄 제거
    %% ─────────────────────────────
    OPEN --> S2(["SCENE 2 — 거미줄 제거하기"])
    S2 --> TC2_ENTRY{"시간 초과?"}

    TC2_ENTRY -->|"time remaining <= 0"| FAIL_S2(["🔴 실패화면으로 이동"])
    TC2_ENTRY -->|"time remaining > 0"| SQUEEZE["스퀴즈 꾹 누르기"]

    SQUEEZE --> GAUGE["게이지 증가\n(50ms 당 +2.75%)"]
    GAUGE --> RELEASE["스퀴즈 손 떼기"]
    RELEASE --> JUDGE{"게이지 판정\n(랜덤하게 바뀌는 지점)"}

    %% 판정 분기
    JUDGE -->|"랜덤 범위 안"| SUCCESS["성공\n(바람 불고 주입)"]
    JUDGE -->|"랜덤 범위 밖"| FAIL_GAUGE["실패"]

    %% 성공 경로
    SUCCESS --> WEB["거미줄 제거 진행\nwebLayerIndex --"]
    WEB --> RANDOM["randomizeRange()\n다음 성공 범위 랜덤 변경"]
    RANDOM --> INC["SuccessCount += 1"]
    INC --> CHECK{"SuccessCount = N ?"}

    %% 실패 경로
    FAIL_GAUGE --> RESET["게이지 리셋\n(범위 유지)"]

    %% 재시도 루프
    RESET --> TC2_RETRY{"시간 초과?"}
    CHECK -->|"False"| RETRY["재달성"]
    RETRY --> TC2_RETRY

    TC2_RETRY -->|"time remaining <= 0"| FAIL_S2
    TC2_RETRY -->|"time remaining > 0"| SQUEEZE

    %% 최종 클리어 판정
    CHECK -->|"True"| FIRE["발동"]
    FIRE --> TC3{"시간 초과?"}

    TC3 -->|"True\ntime remaining <= 0"| STAGE_FAIL["스테이지 3 실패"]
    TC3 -->|"False\ntime remaining > 0"| STAGE_CLEAR["스테이지 3 클리어"]

    STAGE_FAIL  --> FAIL_FINAL(["🔴 실패화면으로 이동"])
    STAGE_CLEAR --> NEXT(["🟢 팀원 뷰로 이동\nstopTimer · recordTime"])

    %% ─────────────────────────────
    %% 스타일
    %% ─────────────────────────────
    style START         fill:#333,color:#fff
    style FAIL_S1       fill:#e74c3c,color:#fff
    style FAIL_S2       fill:#e74c3c,color:#fff
    style FAIL_FINAL    fill:#e74c3c,color:#fff
    style FAIL_GAUGE    fill:#e74c3c,color:#fff
    style STAGE_FAIL    fill:#e74c3c,color:#fff
    style SUCCESS       fill:#27ae60,color:#fff
    style WEB           fill:#27ae60,color:#fff
    style RANDOM        fill:#27ae60,color:#fff
    style OPEN          fill:#27ae60,color:#fff
    style FIRE          fill:#27ae60,color:#fff
    style STAGE_CLEAR   fill:#27ae60,color:#fff
    style NEXT          fill:#27ae60,color:#fff  
```
