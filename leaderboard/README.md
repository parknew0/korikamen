# Korikamen Leaderboard (축제 키오스크용)

서버(`/scores`)에서 랭킹을 받아 **전체화면으로 자동 갱신**해 보여주는 단일 HTML.
웹 배포가 아니라 **현장 노트북/PC에서 로컬로 하루 띄워 쓰는** 용도.

- `index.html` — 리더보드 화면 (포디움 + 순위 리스트, 5초마다 갱신)
- `start.png` — 배경 이미지. 같은 폴더에 두면 배경으로 깔린다. 없으면 어두운 단색.

---

## ⚠️ 먼저: 서버 CORS (1회)

브라우저에서 다른 출처의 서버를 `fetch` 하려면 서버가 **CORS 를 허용**해야 한다.
`server/main.py` 에 이미 추가해 뒀으니, **서버를 한 번 재배포**하면 된다.

```bash
# 서버에서
cd ~/korikamen-ranking      # (배포 폴더)
git pull                    # CORS 반영
docker compose up -d --build
```
이미 main.py 에 다음이 들어가 있다:
```python
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
```

---

## 실행 방법

### 방법 A — 로컬 HTTP 서버 (권장)
`file://` 로 직접 열면 브라우저가 `fetch` 를 막을 수 있어, 간단한 로컬 서버로 여는 게 안전하다.

```bash
cd leaderboard
python3 -m http.server 8000
```
브라우저에서 **http://localhost:8000** 접속 → **F11**(전체화면).

### 방법 B — 그냥 더블클릭
`index.html` 더블클릭(`file://`). 잘 되면 OK지만, 브라우저에 따라 `fetch` 가 막히면 방법 A 를 쓴다.

### 전체화면 / 키오스크
- 일반: 브라우저 **F11**.
- 완전 키오스크(주소창 없이): 예) `chrome --kiosk "http://localhost:8000"`

---

## 웹 배포 (Vercel — 아무나 URL 로 접속)

로컬 대신 인터넷에 띄워 누구나 보게 하려면 Vercel 이 빠르다(무료·HTTPS·CDN).

⚠️ **Mixed Content 처리**: Vercel 은 HTTPS 인데 서버는 HTTP(평문) 라, HTTPS 페이지가 HTTP API 를 직접 부르면 브라우저가 막는다. 그래서 `vercel.json` 으로 **Vercel 이 서버를 대신 호출(프록시)** 하게 했고(`/api/scores` → 서버), `index.html` 은 배포 환경에서 자동으로 그 프록시를 쓴다. (브라우저는 같은 HTTPS 도메인만 보므로 차단 없음)

### 방법 1 — GitHub 연결 (자동 배포, Node 불필요)
1. vercel.com 에 GitHub 계정으로 가입
2. **New Project → `korikamen` 레포 import**
3. **Root Directory 를 `leaderboard` 로 지정** (모노레포라 필수)
4. Deploy → `https://<프로젝트>.vercel.app` 발급
5. 이후 `leaderboard/` 를 push 하면 자동 재배포
> 이 방식은 **`start.png` 도 git 에 올라가 있어야** 배경이 나온다: `git add leaderboard/start.png && git commit && git push`

### 방법 2 — CLI (로컬 폴더째 업로드)
```bash
npm i -g vercel        # Node 필요
cd leaderboard
vercel                 # 브라우저 로그인 후 질문 엔터 → 미리보기 배포
vercel --prod          # 정식 URL
```
로컬 `leaderboard/` 를 그대로 올리므로 `start.png` 가 폴더에 있으면 같이 올라간다.

배포된 URL 을 큰 화면 브라우저에서 열고 F11 → 끝. 갱신·정렬은 그대로 동작한다.

---

## 설정 (index.html 상단 `script`)

```js
const API_URL    = "http://140.245.64.70:8081/scores?limit=100"; // 표시 인원은 limit 으로
const REFRESH_MS = 5000;                                          // 갱신 주기(ms)
```
- 인원을 더/덜 보려면 `limit` 숫자 변경 (서버 최대 100).
- 갱신을 더 자주/덜 하려면 `REFRESH_MS` 변경.

---

## 잘 안 될 때

| 증상 | 확인 |
| --- | --- |
| "서버 연결 실패" 가 계속 뜸 | 서버가 떠 있는지(`/health`), 방화벽 8081, **CORS 재배포 했는지** |
| 콘솔에 `CORS policy` 에러 | 서버 CORS 미반영 → 위 재배포 |
| 데이터가 안 바뀜 | 브라우저 캐시 — 이미 `cache:"no-store"` 적용. 그래도 안 되면 강력 새로고침 |
| 닉네임이 깨짐 | 이미 `escapeHtml` 처리됨. 서버 응답 인코딩(UTF-8) 확인 |

> 현장 팁: 노트북 **절전/화면보호기 끄기**, 충전기 연결, 와이파이 안정 확인. 시작 전에 한 번 `/health` 로 서버 상태를 확인하고 띄우면 안전하다.
