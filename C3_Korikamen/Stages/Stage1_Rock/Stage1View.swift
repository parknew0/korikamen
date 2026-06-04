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
    @State private var scene = Stage1Scene(size: Stage1Layout.designSize)
    @State private var editMode = false
    @State private var showHitboxes = false
    @State private var showTouchMap = false

    // 조정모드(돌무더기/관 위치·크기 실시간 조절)
    @State private var adjustMode = false
    @State private var pileX = Double(Stage1Layout.pilePosition.x)
    @State private var pileY = Double(Stage1Layout.pilePosition.y)
    @State private var pileScale = Double(Stage1Layout.pileScale)
    @State private var coffinX = Double(Stage1Layout.coffinPosition.x)
    @State private var coffinY = Double(Stage1Layout.coffinPosition.y)
    @State private var coffinScale = Double(Stage1Layout.coffinScale)

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
            if adjustMode { adjustPanel }
            #endif
        }
        .onAppear {
            scene.manager = manager
            scene.pressureProvider = { let p = pencil.state.pressure; return p > 0 ? p : 0.5 }
            timer.start()
        }
        .onChange(of: editMode) { _, on in scene.editMode = on }
        .onChange(of: showHitboxes) { _, on in scene.showHitboxes = on }
        .onChange(of: showTouchMap) { _, on in scene.showTouchMap = on }
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
                Toggle("조정모드", isOn: $adjustMode).fixedSize()
                Toggle("배치모드", isOn: $editMode).fixedSize()
                Toggle("히트박스", isOn: $showHitboxes).fixedSize()
                Toggle("터치맵", isOn: $showTouchMap).fixedSize()
                Spacer()
                Button("클리어 →", action: onClear)
                Button("실패", role: .destructive, action: onFail)
            }
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }

    /// 돌무더기/관의 위치·크기를 실시간으로 조절하는 패널.
    private var adjustPanel: some View {
        VStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("조정모드 — 실시간 미리보기").font(.caption).bold()
                adjustRow("무더기 X", $pileX, 0...1024)
                adjustRow("무더기 Y", $pileY, -150...900)
                adjustRow("무더기 크기", $pileScale, 0.2...1.5)
                Divider()
                adjustRow("관 X", $coffinX, 0...1024)
                adjustRow("관 Y", $coffinY, -150...900)
                adjustRow("관 크기", $coffinScale, 0.2...2.0)
                Button("값 출력 → 콘솔") { scene.dumpTransform() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
            .padding(12)
            .frame(width: 320)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func adjustRow(_ name: String, _ value: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        HStack {
            Text(name).font(.caption2).frame(width: 70, alignment: .leading)
            Slider(value: value, in: range) { _ in applyTransform() }
                .onChange(of: value.wrappedValue) { _, _ in applyTransform() }
            Text(String(format: "%.2f", value.wrappedValue))
                .font(.caption2).monospacedDigit().frame(width: 52, alignment: .trailing)
        }
    }

    /// 슬라이더 값을 씬에 즉시 반영.
    private func applyTransform() {
        scene.pilePosition = CGPoint(x: pileX, y: pileY)
        scene.pileScale = CGFloat(pileScale)
        scene.coffinPosition = CGPoint(x: coffinX, y: coffinY)
        scene.coffinScale = CGFloat(coffinScale)
    }
    #endif
}
