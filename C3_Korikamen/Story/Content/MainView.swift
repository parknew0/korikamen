//
//  MainView.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//

import SwiftUI

struct MainView: View {
    let onStart: () -> Void
    @State private var showTutorial = false

    var body: some View {
        ZStack {
            // 타이틀 — 상단 중앙
            VStack {
                Image("txt_start_title_topmiddle")
                    .resizable().scaledToFit()
                    .frame(maxWidth: 600)
                    .padding(.top, 30)
                Spacer()
            }

            // 시작 버튼 — 하단 중앙
            VStack {
                Spacer()
                Button { onStart() } label: {
                    Image("btn_start_middledown_square_gold")
                        .resizable().scaledToFit().frame(width: 280)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 60)
            }

            // 도움말 버튼 — 좌상단
            VStack {
                HStack {
                    // 변경 후: clear 리퀴드 글라스 원 위에 물음표
                    Button { withAnimation { showTutorial = true } } label: {
                        Image(systemName: "questionmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .glassEffect(.clear.tint(.white.opacity(0.12)), in: Circle())  // 살짝 뿌옇게
                            .contentShape(Circle())          // ← 원 전체가 터치 영역
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                Spacer()
            }
            .padding(20)

            // 튜토리얼 모달
            if showTutorial {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    Image("tutorial").resizable().scaledToFit().padding(40)
                }
                .contentShape(Rectangle())
                .onTapGesture { withAnimation { showTutorial = false } }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(                                   // ← 핵심: 배경을 모디파이어로
            Image("bg_start")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()                     // 배경만 화면 끝까지 bleed
        )
    }
}
