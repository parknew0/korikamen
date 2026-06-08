//
//  ContentView.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//
//  game.phase에 따라 화면을 전환하는 라우터.
//
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var game: GameManager

    var body: some View {
        routedView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomLeading) {
                #if DEBUG
                MockPencilFeeder()
                #endif
            }
    }

    @ViewBuilder private var routedView: some View {
        if let failed = game.failedStage {
            FailView(stage: failed, onRetry: game.retry, onMain: game.goToMain)
        } else {
            switch game.phase {
            case .main:     MainView(onStart: game.advance)
            case .intro:    StoryView(player: StoryPlayer(pages: introStory, onFinish: game.advance)) // 인트로 추가
                
            // 각 스테이지를 시작화면+튜토리얼 게이트로 감쌈
            case .stage(1):
                StageStartView(titleImage: "Stage1_Main",
                    tutorialImage: "img_stage1tutorial_papyrus") {
                        Stage1View(onClear: game.advance, onFail: game.fail)
                    }
            case .stage(2):
                StageStartView(titleImage: "Stage2_Main",
                    tutorialImage: "img_stage2tutorial_papyrus") {
                        Stage2View(onClear: game.advance, onFail: game.fail)
                    }
            case .stage(3):
                StageStartView(titleImage: "Stage3_Main",
                    tutorialImage: "img_stage3tutorial_papyrus",
                        startButtonImage: "btn_stage3tutorial(btn_normal)_start_normal") {   // ← Stage3 전용
                    Stage3View(onClear: game.advance, onFail: game.fail)
                }
    
            case .interlude(1): StoryView(player: StoryPlayer(pages: stage1Story, onFinish: game.advance))   // ← 추가
            case .interlude(2): StoryView(player: StoryPlayer(pages: stage2Story, onFinish: game.advance))   // ← 추가
                
            case .interlude: EmptyView()                                                                  // ← 안전장치 추가
            case .stage:     EmptyView()
            case .ending:    EndingView(onReplay: game.advance)
            }
        }
    }
}
