//
//  EndingView.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//  엔딩뷰 -> 마지막 컷에서 총 클리어 시간 + 닉네임 입력으로 랭킹 등록 후 메인으로 이동
//

import SwiftUI
import Combine

struct EndingView: View {
    let onReplay: () -> Void // 엔딩이 끝났을 때 실행할 동작 -> game.advance

    @EnvironmentObject var game: GameManager       // 총 플레이타임 game.totalPlayTime 사용
    @StateObject private var player: StoryPlayer    // 시나리오 컷 관리
    @StateObject private var ranking = RankingStore() // 랭킹 저장/조회
    @State private var nickname = ""
    @State private var showRanking = false

    init(onReplay: @escaping () -> Void) {
        self.onReplay = onReplay
        _player = StateObject(wrappedValue: StoryPlayer(pages: endingStory, onFinish: onReplay))
    }

    var body: some View {
        ZStack {
            StoryView(player: player, showSkip: false) // 엔딩은 Skip 버튼 숨김

            if player.index == endingStory.count - 1 { // 마지막 컷이면 점수 등록 화면
                scoreSubmitOverlay
                    .onAppear { MainBGM.play() }
                    .onDisappear { MainBGM.stop() } // ← 메인 벗어나면 정지
            }
        }
    }

    // 총 클리어 시간 표시 + 닉네임 입력 + 랭킹 등록
    private var scoreSubmitOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text("총 클리어 시간")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                    // 점수는 게임이 측정한 값이라 사용자가 바꿀 수 없다
                    Text(RankingFormat.clock(timeMs: timeMs))
                        .font(Font.custom("NovaMono-Regular", size: 44))
                        .foregroundStyle(.white)
                }

                if ranking.didSubmit {
                    Text("랭킹에 등록됐어요!")
                        .font(.headline)
                        .foregroundStyle(.green)

                    HStack(spacing: 16) {
                        Button { showRanking = true } label: { overlayButton("랭킹 보기") }
                        Button { onReplay() } label: { overlayButton("메인으로") }
                    }
                } else {
                    TextField("닉네임 입력", text: $nickname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        .frame(width: 280)

                    if let message = ranking.errorMessage {
                        Text(message).font(.footnote).foregroundStyle(.red)
                    }

                    Button {
                        Task { await ranking.submit(nickname: trimmedNickname, timeMs: timeMs) }
                    } label: {
                        overlayButton(ranking.isLoading ? "등록 중…" : "랭킹 등록")
                    }
                    .disabled(trimmedNickname.isEmpty || ranking.isLoading)
                    .opacity(trimmedNickname.isEmpty ? 0.5 : 1)

                    Button { onReplay() } label: {
                        Text("등록 없이 메인으로")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 28)
            .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        }
        .fullScreenCover(isPresented: $showRanking) {
            RankingView(onClose: { showRanking = false })
        }
    }

    private func overlayButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 22)
            .background(.white.opacity(0.18), in: Capsule())
    }

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 초(Double) → 밀리초(Int). 게임이 측정한 시간이라 사용자가 못 바꾼다.
    private var timeMs: Int {
        RankingFormat.milliseconds(fromSeconds: game.totalPlayTime)
    }
}
