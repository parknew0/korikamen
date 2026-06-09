//
//  FailView.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//
//
//  공용 실패 화면. 어떤 스테이지든 실패하면 여기로.
//

import SwiftUI

struct FailView: View {
    let stage: Int               // 호출부 시그니처 유지용(현재 화면엔 미표시)
    let onRetry: () -> Void      // 다시 시작
    let onMain: () -> Void       // 시작(메인으로)
    @State private var played = false //중복 재생 방지
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()        // 검은 배경

            VStack(spacing: 100) {
                // 게임오버 큰 이미지
                Image("gameover_gameover")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 500)        // 크기 상한 — 조절

                // 다시시작 / 시작 버튼 (가로 정렬)
                HStack(spacing: 90) {
                    Button { onRetry() } label: {
                        Image("gameover_retry_normal")
                            .resizable().scaledToFit().frame(width: 150)
                    }
                    .buttonStyle(.plain)

                    Button { onMain() } label: {
                        Image("gameover_start_normal")
                            .resizable().scaledToFit().frame(width: 150)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .onAppear {
            if !played {
                GameOverBGM.play()
                played = true
            }
        }
    }
}
