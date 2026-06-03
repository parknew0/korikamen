//
//  Stage1View.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//

import SwiftUI
import SpriteKit

struct Stage1View: View {
    let onClear: () -> Void
    let onFail: () -> Void

    @StateObject private var timer = CountdownTimer(duration: 60)   // 60초 임시값(TBD)
    @State private var scene = Stage1Scene(size: Stage1Scene.designSize)

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text("남은 시간: \(Int(timer.remaining))초")
                        .monospacedDigit()
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                Spacer()
            }
            .padding()

            #if DEBUG
            // 배치 모드 도구 + 네비게이션(개발용)
            VStack {
                Spacer()
                HStack {
                    Button("좌표 출력") { scene.dumpPositions() }
                        .buttonStyle(.borderedProminent)
                    Spacer()
                    Button("클리어 →", action: onClear)
                    Button("실패", role: .destructive, action: onFail)
                }
            }
            .padding()
            #endif
        }
        .onAppear { timer.start() }
        .onChange(of: timer.isTimeOver) { _, over in if over { onFail() } }
    }
}
