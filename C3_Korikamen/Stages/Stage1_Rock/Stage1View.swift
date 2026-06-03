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

    @EnvironmentObject private var pencil: PencilInput
    @StateObject private var manager = Stage1GameManager()
    @StateObject private var timer = CountdownTimer(duration: 60)   // 60초 임시값(TBD)
    @State private var scene = Stage1Scene(size: Stage1Scene.designSize)
    @State private var editMode = false
    @State private var showHitboxes = false

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            // 상단 HUD: 남은 시간 + 도구 전환
            VStack {
                HStack {
                    Text("남은 시간: \(Int(timer.remaining))초")
                        .monospacedDigit()
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                    toolButton
                }
                Spacer()
            }
            .padding()

            #if DEBUG
            debugBar
            #endif
        }
        .onAppear {
            scene.manager = manager
            scene.pressureProvider = { let p = pencil.state.pressure; return p > 0 ? p : 0.5 }
            timer.start()
        }
        .onChange(of: editMode) { _, on in scene.editMode = on }
        .onChange(of: showHitboxes) { _, on in scene.showHitboxes = on }
        .onChange(of: timer.isTimeOver) { _, over in if over { onFail() } }
        .onChange(of: manager.didClear) { _, cleared in if cleared { timer.stop(); onClear() } }
        .onChange(of: manager.didDamageCoffin) { _, hit in
            if hit {
                timer.stop()
                scene.flashFail()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onFail() }
            }
        }
    }

    /// 도구 전환 버튼(드릴 ↔ 끌).
    private var toolButton: some View {
        Button {
            manager.selectTool(manager.tool == .drill ? .chisel : .drill)
        } label: {
            Label(manager.tool == .drill ? "드릴" : "끌",
                  systemImage: manager.tool == .drill ? "wrench.and.screwdriver.fill" : "hammer.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(manager.tool == .drill ? .orange : .blue)
    }

    #if DEBUG
    private var debugBar: some View {
        VStack {
            Spacer()
            HStack {
                Toggle("배치모드", isOn: $editMode).fixedSize()
                Toggle("히트박스", isOn: $showHitboxes).fixedSize()
                Button("좌표 출력") { scene.dumpPositions() }
                Spacer()
                Button("클리어 →", action: onClear)
                Button("실패", role: .destructive, action: onFail)
            }
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }
    #endif
}
