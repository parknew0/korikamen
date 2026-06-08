//
//  StageStartView.swift
//  C3_Korikamen
//
//  Created by Park on 6/8/26.
//

import SwiftUI

/// 스테이지 진입 게이트: 시작화면 → (탭) 튜토리얼 겹침 → (탭) 실제 게임.
/// 게임 콘텐츠는 .playing 단계에서야 생성되므로 타이머 등은 그때 시작된다.
struct StageStartView<Content: View>: View {
    let titleImage: String        // 스테이지 시작화면 이미지
    let tutorialImage: String     // 시작화면 위에 겹쳐질 튜토리얼 이미지
    var startButtonImage: String = "btn_stagetutorial(btn_normal)_start_normal"
    @ViewBuilder var content: () -> Content   // 실제 게임 뷰

    private enum Phase { case title, tutorial, playing }
    @State private var phase: Phase = .title

    var body: some View {
        if phase == .playing {
            content()
        } else {
            ZStack {
                // 튜토리얼: 파피루스 하단 밀착 + 우측 하단 시작 버튼
                if phase == .tutorial {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack {
                        Spacer()
                        Image(tutorialImage)
                            .resizable()
                            .scaledToFit()                  // 비율 유지(안 깨짐)
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .bottomTrailing) {
                                Button { phase = .playing } label: {
                                    Image(startButtonImage)
                                        .resizable().scaledToFit().frame(width: 200)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 120)    // 왼쪽으로 옮긴 값
                                .padding(.bottom, 40)
                            }
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(                                     // ← 메인화면과 동일 방식
                Image(titleImage)
                    .resizable()
                    .scaledToFill()                         // 비율 유지하며 채움
                    .ignoresSafeArea()
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if phase == .title {
                    withAnimation(.easeInOut(duration: 0.25)) { phase = .tutorial }
                }
                // tutorial 단계: 화면 탭 무시 → 버튼으로만 시작
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    StageStartView(titleImage: "stage1title",
                   tutorialImage: "img_stage1tutorial_papyrus") {
        Color.black
    }
}

