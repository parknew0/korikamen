//
//  RankingStore.swift
//  C3_Korikamen
//
//  랭킹 화면이 바인딩하는 상태. 내부에서 RankingService(계약)만 호출한다.
//

import Foundation

@MainActor
final class RankingStore: ObservableObject {
    @Published var entries: [ScoreEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSubmit = false

    private let service: RankingService

    init(service: RankingService = RemoteRankingService()) {
        self.service = service
    }

    /// 상위 랭킹 불러오기 (빠른 순)
    func load(limit: Int = 20) async {
        isLoading = true
        errorMessage = nil
        do {
            entries = try await service.topScores(limit: limit)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "랭킹을 불러오지 못했어요."
        }
        isLoading = false
    }

    /// 기록 저장 (점수는 게임이 측정한 값, 닉네임만 사용자가 입력)
    func submit(nickname: String, timeMs: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            try await service.submit(nickname: nickname, timeMs: timeMs)
            didSubmit = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "등록에 실패했어요."
        }
        isLoading = false
    }
}
