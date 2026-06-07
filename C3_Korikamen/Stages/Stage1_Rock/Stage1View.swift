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

    // 조정모드(돌무더기/관 위치·크기 실시간 조절) — 저장된 값으로 시작(없으면 기본값)
    @State private var adjustMode = false
    @State private var pileX = Double(Stage1Transform.load().pilePosition.x)
    @State private var pileY = Double(Stage1Transform.load().pilePosition.y)
    @State private var pileScale = Double(Stage1Transform.load().pileScale)
    @State private var coffinX = Double(Stage1Transform.load().coffinPosition.x)
    @State private var coffinY = Double(Stage1Transform.load().coffinPosition.y)
    @State private var coffinScale = Double(Stage1Transform.load().coffinScale)
    
    // 시간 임박(15초 이하) 경고 상태
    private var isTimeWarning: Bool { timer.remaining <= 15 && timer.remaining > 0 }
    
    var body: some View {
        ZStack {
            Image("Stage1Background") //배경 추가
                .resizable()
                .scaledToFill() //화면 꽉 채우기
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            WarningBorderView(isWarning: isTimeWarning)
            
            SpriteView(scene: scene, options: [.allowsTransparency]) // spritekit 배경 투명하게 설정
                .ignoresSafeArea()

            // 상단 HUD: 남은 시간 + 도구 전환
            VStack {
                topHUD
                Spacer()
                HStack {
                    Spacer()
                    toolButton
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
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
            applyTransform()   // 저장된(또는 기본) 위치·배율을 씬에 반영 — 릴리스 포함 항상
            timer.start()
        }
        .onChange(of: pencil.state.location)   { _, _ in feedPencil() }
        .onChange(of: pencil.state.isTouching) { _, _ in feedPencil() }
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
    
    //테스트(타이머 확인용) <- 맥스 형님 확인 부탁드립니다.
    private var topHUD: some View {
        HStack{
            // 좌측 상단 타이틀
            Image("Stage1_Title")
                .resizable()
                .scaledToFit()
                .frame(height: 60)

            Spacer()

            //우측 상단 타이머
            TimerHUDView(remaining: timer.remaining,
                         normalImage: "Stage12Timer",
                         warningImage: "Stage3Timer")
        }
        .padding(.horizontal, 30)
        .padding(.top, 20)
        
    //테스트(타이머 확인용)  <- 맥스 형님 확인 부탁드립니다.
        
    }
    
    private var toolButton: some View {
        Button {
            manager.selectTool(manager.tool == .drill ? .chisel : .drill)
        } label: {
            ZStack {
                Circle()
                    .fill(.clear)
                    .glassEffect(.clear, in: Circle())
                    .opacity(0.75)                 // ← 배경만 더 투명하게 (아이콘 영향 X)
                Image(manager.tool == .drill ? "drill" : "chisel")
                    .resizable()
                    .scaledToFit()
                    .padding(28)
            }
            .frame(width: 120, height: 120)
        }
        .buttonStyle(.plain)
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
            //.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
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
                HStack {
                    Button("값 출력 → 콘솔") { scene.dumpTransform() }
                        .buttonStyle(.borderedProminent)
                    Button("기본값 복원", role: .destructive) {
                        Stage1Transform.reset()
                        let d = Stage1Transform.fallback
                        pileX = Double(d.pilePosition.x); pileY = Double(d.pilePosition.y)
                        pileScale = Double(d.pileScale)
                        coffinX = Double(d.coffinPosition.x); coffinY = Double(d.coffinPosition.y)
                        coffinScale = Double(d.coffinScale)
                        applyTransform()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(12)
            .frame(width: 320)
            // .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
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

    #endif

    /// 현재 값을 씬에 즉시 반영하고 UserDefaults에 저장(재시작 후에도 유지).
    /// 적용은 릴리스 포함 항상, 저장은 조정모드에서 값이 바뀔 때 호출된다.
    private func applyTransform() {
        scene.pilePosition = CGPoint(x: pileX, y: pileY)
        scene.pileScale = CGFloat(pileScale)
        scene.coffinPosition = CGPoint(x: coffinX, y: coffinY)
        scene.coffinScale = CGFloat(coffinScale)
        Stage1Transform(pilePosition: CGPoint(x: pileX, y: pileY),
                        pileScale: CGFloat(pileScale),
                        coffinPosition: CGPoint(x: coffinX, y: coffinY),
                        coffinScale: CGFloat(coffinScale)).save()
    }
    
    /// 계약(PencilState)의 위치·접촉을 씬에 전달 — Stage2/3와 동일한 입력 경로.
    private func feedPencil() {
        scene.applyPencil(viewLocation: pencil.state.isTouching ? pencil.state.location : nil,
                          isActive: pencil.state.isTouching)
    }
}
