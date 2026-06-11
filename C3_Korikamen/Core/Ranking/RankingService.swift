//
//  RankingService.swift
//  C3_Korikamen
//
//  랭킹 서버 통신 "계약"(프로토콜)과 구현.
//  게임/뷰 코드는 RankingService 계약에만 의존하고 URLSession 을 직접 호출하지 않는다.
//  (애플펜슬 입력을 PencilState 로 감싼 것과 같은 방식)
//

import Foundation

// MARK: - 서버 설정 (주소는 이 한 곳에서만 관리)

enum RankingConfig {
    /// 랭킹 서버 주소. HTTPS 준비되면 https://kandu.kr, 평문 포트로 노출하면 http://kandu.kr:8081.
    static let baseURL = URL(string: "https://kandu.kr")!

    /// 점수 위조 방지 키. 서버 .env 의 API_KEY 와 같은 값. 안 쓰면 nil.
    static let apiKey: String? = nil
}

enum RankingError: LocalizedError {
    case server
    case decoding

    var errorDescription: String? {
        switch self {
        case .server:   return "서버와 통신하지 못했어요."
        case .decoding: return "랭킹 데이터를 읽지 못했어요."
        }
    }
}

// MARK: - 계약

protocol RankingService {
    /// 기록 저장 (닉네임 + 걸린 시간 ms)
    func submit(nickname: String, timeMs: Int) async throws
    /// 빠른 순 상위 랭킹
    func topScores(limit: Int) async throws -> [ScoreEntry]
}

// MARK: - 실제 서버 구현

struct RemoteRankingService: RankingService {
    var baseURL: URL = RankingConfig.baseURL
    var apiKey: String? = RankingConfig.apiKey
    var session: URLSession = .shared

    func submit(nickname: String, timeMs: Int) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("scores"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey { request.setValue(apiKey, forHTTPHeaderField: "X-API-Key") }
        request.httpBody = try JSONEncoder().encode(ScoreSubmission(nickname: nickname, timeMs: timeMs))

        let (_, response) = try await session.data(for: request)
        try Self.ensureOK(response)
    }

    func topScores(limit: Int) async throws -> [ScoreEntry] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("scores"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

        let (data, response) = try await session.data(from: components.url!)
        try Self.ensureOK(response)
        do {
            return try JSONDecoder().decode([ScoreEntry].self, from: data)
        } catch {
            throw RankingError.decoding
        }
    }

    private static func ensureOK(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw RankingError.server
        }
    }
}

// MARK: - 프리뷰·오프라인용 스텁 (서버 없이도 화면이 도는 워킹 스켈레톤)

struct StubRankingService: RankingService {
    func submit(nickname: String, timeMs: Int) async throws { }
    func topScores(limit: Int) async throws -> [ScoreEntry] {
        [
            ScoreEntry(rank: 1, nickname: "민수", timeMs: 61_230),
            ScoreEntry(rank: 2, nickname: "지은", timeMs: 73_540),
            ScoreEntry(rank: 3, nickname: "코리", timeMs: 88_010),
        ]
    }
}
