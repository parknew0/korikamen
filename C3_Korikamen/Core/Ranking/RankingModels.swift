//
//  RankingModels.swift
//  C3_Korikamen
//
//  랭킹 데이터 모델과 시간 포맷 헬퍼.
//  서버 계약: POST /scores {nickname, timeMs} · GET /scores?limit=N -> [{rank, nickname, timeMs}]
//

import Foundation

/// 랭킹 한 줄 (서버 GET /scores 응답 항목)
struct ScoreEntry: Codable, Identifiable {
    let rank: Int
    let nickname: String
    let timeMs: Int
    var id: Int { rank }
}

/// 점수 제출 바디 (POST /scores)
struct ScoreSubmission: Encodable {
    let nickname: String
    let timeMs: Int
}

/// 시간 변환·표시 헬퍼
enum RankingFormat {
    /// 초(Double) → 밀리초(Int). 서버는 ms 정수로 보관·정렬한다.
    static func milliseconds(fromSeconds seconds: Double) -> Int {
        Int((seconds * 1000).rounded())
    }

    /// 밀리초 → "n분 nn초"
    static func clock(timeMs: Int) -> String {
        let totalSeconds = max(0, timeMs) / 1000
        return String(format: "%d분 %02d초", totalSeconds / 60, totalSeconds % 60)
    }
}
