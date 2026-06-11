# Korikamen Ranking Server

게임 클리어 기록(닉네임 + 기록시간)을 저장하고, 빠른 순으로 랭킹을 돌려주는 아주 단순한 REST API.
여러 기기(TestFlight 내부 테스터)가 같은 서버를 바라보게 해서 공통 랭킹을 만든다.

- **스택**: FastAPI + SQLite + Docker (의존성 최소, DB 파일 1개)
- **호스팅**: OCI Always Free, Ampere A1(ARM), 춘천 리전
- **저장**: `scores(id, nickname, time_ms, created_at)` 테이블 하나

---

## 1. API 명세

| 메서드 | 경로 | 설명 |
| --- | --- | --- |
| `POST` | `/scores` | 기록 저장. body: `{"nickname": "홍길동", "timeMs": 73210}` |
| `GET`  | `/scores?limit=20` | `time_ms` 오름차순(빠른 순) 랭킹 반환 |
| `GET`  | `/health` | 헬스 체크 |

- `nickname`: 1~12자(앞뒤 공백 제거). `timeMs`: 1 ~ 86,400,000(24시간) 범위만 허용 → 비정상 기록 차단.
- 자동 문서: 서버 띄운 뒤 `http://<IP>:8080/docs` 에서 바로 테스트 가능.

`GET /scores` 응답 예시:

```json
[
  { "rank": 1, "nickname": "민수", "timeMs": 61230 },
  { "rank": 2, "nickname": "홍길동", "timeMs": 73210 }
]
```

> **점수 위조 방지(선택)**: `.env` 에 `API_KEY` 를 넣으면 `POST /scores` 에 `X-API-Key` 헤더가 필요해진다.
> 인증 없는 공개 POST 는 누구나 가짜 점수를 넣을 수 있으니, 내부 테스트라도 가벼운 키 하나 두는 걸 권장.

---

## 2. 로컬에서 먼저 돌려보기 (선택)

```bash
cd server
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
DB_PATH=scores.db uvicorn main:app --reload --port 8080
# 다른 터미널에서:
curl -X POST localhost:8080/scores -H 'content-type: application/json' \
     -d '{"nickname":"테스트","timeMs":73210}'
curl localhost:8080/scores
```

---

## 3. OCI 인스턴스 만들기 (춘천 · ARM · Always Free)

### 3-1. 계정 / 리전
1. OCI 가입 → 신용/체크카드로 본인확인(소액 인증 홀드). **홈 리전을 `South Korea Central (Chuncheon)` 으로** 선택. (Always Free 자원은 홈 리전에 묶이며 변경 불가)
2. 춘천은 단일 가용 도메인(`AP-CHUNCHEON-1-AD-1`).

### 3-2. 인스턴스 생성
**Compute → Instances → Create instance**

| 항목 | 값 |
| --- | --- |
| Image | **Canonical Ubuntu 24.04 (aarch64)** — ARM용 `aarch64` 꼭 확인 |
| Shape | **Ampere → VM.Standard.A1.Flex** |
| OCPU / RAM | 1 OCPU / 6 GB 면 이 서버엔 충분 (무료 한도는 4 OCPU·24 GB) |
| SSH key | 로컬에서 만든 공개키 붙여넣기 (`ssh-keygen -t ed25519`) |
| Networking | 새 VCN 자동 생성, **public IPv4 할당** 체크 |

> **"Out of host capacity" 가 뜨면**: 춘천은 AD가 1개라 AD 전환 트릭을 못 쓴다. 가장 확실한 해결은 **계정을 Pay As You Go(PAYG)로 업그레이드** — 무료 한도 안에서 쓰면 과금은 0원이고, 하드웨어 우선순위가 생긴다. (idle 회수 방지 효과도 덤)

### 3-3. 공인 IP 고정 (하드코딩 전제라면 필수)
인스턴스의 임시 공인 IP를 **Reserved Public IP(예약 공인 IP)** 로 변경.
→ *Instance → Attached VNICs → IP addresses → 기존 IP 편집 → "Reserved public IP"*.
이렇게 해야 인스턴스를 지웠다 만들어도 같은 IP가 유지되어, 앱에 박아 둔 주소를 안 바꿔도 된다.

---

## 4. 서버 배포 (Docker)

### 4-1. 접속 & Docker 설치
```bash
ssh ubuntu@<공인IP>

# Docker 설치
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2 git
sudo usermod -aG docker ubuntu      # 재로그인 후 sudo 없이 docker 사용
```

### 4-2. 코드 올리고 실행
```bash
# 이 레포에서 server 폴더만 받아도 되고, 전체 clone 후 server 로 이동해도 된다
git clone <이 레포 URL> korikamen && cd korikamen/server

# (선택) 점수 위조 방지 키 설정
cp .env.example .env && nano .env   # API_KEY=원하는값

docker compose up -d --build
docker compose logs -f              # 정상 기동 확인 (Ctrl+C 로 빠져나오기)
```

> **같은 인스턴스에 8080을 쓰는 다른 앱(예: Spring Boot)이 이미 있을 때**: 한 서버에 Docker 컨테이너 여러 개는 정상이다. "호스트 포트"만 안 겹치면 된다. 이 compose 는 호스트 `8081`을 쓰므로(8080은 기존 앱) 그대로 공존하고, 방화벽도 8081을 연다. 경로(`/scores`)도 기존 `/menus`와 달라 충돌 없다.

### 4-3. 방화벽 2겹 열기 ⚠️ 가장 많이 막히는 부분
OCI는 **클라우드 방화벽 + OS 방화벽** 두 겹이라 둘 다 열어야 한다.

**(a) OCI 보안 목록 (콘솔)**: VCN → Security List → Ingress Rule 추가
`Source 0.0.0.0/0 · IP Protocol TCP · Destination Port 8081`

**(b) OS 방화벽 (Ubuntu 24.04, iptables)**:
```bash
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8081 -j ACCEPT
sudo netfilter-persistent save
```

확인: 다른 기기 브라우저에서 `http://<공인IP>:8081/health` → `{"status":"ok"}` 가 보이면 성공.

---

## 5. 앱(iOS) 연동

### 5-1. ATS — HTTP(평문) 허용
IP+HTTP 라서 `Info.plist` 에 예외가 필요하다. TestFlight **내부 테스트**는 심사가 없어 그대로 통과한다.

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 5-2. 호출 예시 (URLSession)
서버 주소는 **상수 한 곳**에만 둔다. 나중에 도메인/HTTPS로 바꿀 때 이 줄만 고치면 된다.

```swift
enum RankingAPI { static let baseURL = "http://<공인IP>:8081" }

// 저장
struct ScoreIn: Encodable { let nickname: String; let timeMs: Int }
func submit(_ nickname: String, _ timeMs: Int) async throws {
    var req = URLRequest(url: URL(string: "\(RankingAPI.baseURL)/scores")!)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    // API_KEY 를 쓴다면: req.setValue("키값", forHTTPHeaderField: "X-API-Key")
    req.httpBody = try JSONEncoder().encode(ScoreIn(nickname: nickname, timeMs: timeMs))
    _ = try await URLSession.shared.data(for: req)
}

// 랭킹 조회
struct Rank: Decodable { let rank: Int; let nickname: String; let timeMs: Int }
func topRanks(limit: Int = 20) async throws -> [Rank] {
    let url = URL(string: "\(RankingAPI.baseURL)/scores?limit=\(limit)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([Rank].self, from: data)
}
```

> 앱 구조 팁(`docs/architecture.md` 철학): 위 호출은 `RankingService` 프로토콜로 감싸고, 서버가 없을 때 도는 로컬 스텁을 같이 두면 랭킹 화면을 서버 완성 전에도 끝까지 돌릴 수 있다(워킹 스켈레톤).

---

## 6. 운영 메모

- **IP 고정**: §3-3 Reserved Public IP 필수. 안 하면 인스턴스 재생성 때 IP가 바뀌어 앱을 다시 빌드해야 한다.
- **idle 회수**: 무료 인스턴스는 7일간 CPU 95퍼센타일 < 20% 면 회수 대상. 랭킹 서버는 트래픽이 적어 해당될 수 있으니 **PAYG 전환**으로 방지(무료 한도 내 과금 0).
- **백업**: 기록은 `server/data/scores.db` 파일 하나. 가끔 `scp` 로 받아 두면 끝.
- **업데이트**: 코드 변경 후 `git pull && docker compose up -d --build`.
- **나중에 HTTPS로**: 무료 도메인(DuckDNS) + Let's Encrypt + nginx 를 붙이면 ATS 예외를 끄고 정식 HTTPS로 갈 수 있다. 그때도 앱은 §5-2의 `baseURL` 한 줄만 바꾸면 된다.

---

## 7. GitHub Actions 자동 배포 (선택)

`main` 의 `server/` 가 바뀌면 OCI 서버에 자동으로 재배포된다(`.github/workflows/deploy-ranking.yml`).
동작: 체크아웃 → `server/` 를 서버 `~/korikamen-ranking` 로 복사 → 그 폴더에서 `docker compose up -d --build`.

### 넣어야 할 GitHub Secrets
레포 → **Settings → Secrets and variables → Actions → New repository secret**

| 이름 | 값 | 필수 |
| --- | --- | --- |
| `OCI_SSH_HOST` | 서버 공인 IP | ✅ |
| `OCI_SSH_USER` | `ubuntu`(Ubuntu) 또는 `opc`(Oracle Linux) | ✅ |
| `OCI_SSH_KEY` | SSH **개인키 전체** (`-----BEGIN ... -----END ...`) | ✅ |
| `OCI_SSH_PORT` | SSH 포트 (기본 22면 **생략 가능**) | ⬜ |
| `RANKING_API_KEY` | 점수 위조 방지 키 (쓸 때만) | ⬜ |

> ⚠️ IP·포트는 비밀이 아니지만, **`OCI_SSH_KEY`(SSH 개인키)는 진짜 비밀**이다. 절대 코드/커밋에 넣지 말고 Secret 으로만 둔다.

### 서버 사전 준비 (최초 1회)
- Docker / docker compose 설치, 배포 사용자가 docker 그룹에 포함: `sudo usermod -aG docker $USER` 후 재로그인 (sudo 없이 `docker` 실행되게).
- Actions 가 쓸 SSH **공개키**를 서버 `~/.ssh/authorized_keys` 에 등록. 그 짝인 **개인키**를 `OCI_SSH_KEY` Secret 에 넣는다. (인스턴스 만들 때 쓴 키를 재사용해도 되지만, CI 전용 키페어를 새로 만드는 편이 더 안전)
- 방화벽 2겹에 포트 개방 (§4-3).

> 처음엔 Actions 탭에서 **Run workflow**(수동 실행)로 한 번 돌려 SSH·배포가 되는지 확인한 뒤, 이후 push 자동 배포를 쓰면 된다.
