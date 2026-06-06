//
//  TypewriterText.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/5/26.
//  텍스트 타이핑 효과 기능

import Foundation
import SwiftUI

struct TypewriterText: View {
    let fullText: String                 // 전체 텍스트
    let beat: StoryPlayer.Beat
    var speed: TimeInterval = 0.05        // 한 글자당 시간
    var onFinished: () -> Void = {}       // 타이핑 완료 시 호출
    @State private var shown = ""         // 지금까지 보인 글자
    @State private var timer: Timer?
    
    var body: some View {
        Text(.init(shown)) // ← String을 마크다운으로 해석
            .onAppear { start() }
            .onChange(of: beat) { _, newBeat in
                if newBeat == .settled {
                    skip()  // ← settled 되면 즉시 전체 표시
                }
            }
    }
    
    private func start() {
        shown = ""
        var index = 0
        timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { t in
            
            guard index < fullText.count else { t.invalidate()
                onFinished()
                return
            }
            
            let i = fullText.index(fullText.startIndex, offsetBy: index)
            shown.append(fullText[i])
            index += 1
        }
    }
    private func skip() {
        timer?.invalidate()           // 타이핑 멈추고
        shown = fullText
        onFinished()    // 스킵해도 완료 처리 + 전체 즉시 표시    
    }
}
