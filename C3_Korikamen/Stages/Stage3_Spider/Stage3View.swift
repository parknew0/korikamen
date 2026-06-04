//
//  Stage3View.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//

import SwiftUI
import SpriteKit

struct Stage3View: View {
    let onClear: () -> Void
    let onFail: () -> Void
    
    @StateObject private var timer = CountdownTimer(duration: 90)    // 90초 (기획값)
    @EnvironmentObject private var pencil: PencilInput // 펜슬 입력
    @StateObject private var manager = Stage3GameManager() // 로직 클래스 불러오기
    
    @State private var coffinScene: Stage3CoffinScene = { //관 scene 인스턴스 변수
        let s = Stage3CoffinScene(size:CGSize(width: 550,height: 1100)) //세로
        s.scaleMode = .aspectFit
        return s
    }()
    @State private var dragStartX : CGFloat? = nil // 드래그 시작시 x 기준
    @State private var fadeOpacity: Double = 0 //씬1 -> 2로 전환시 나올 검은막 투명도
    @State private var wipeProgress: Double = 0   // webindexlayer 상태 전용, 0=안 걷힘, 1=완전히 걷힘

    private let dragRequiredDistance: CGFloat = 200 // 기준 이동거리 (임시입니다!!!!)
    
    //세로 게이지 바 (테스트용)
    private var gaugeBar : some View {
        GeometryReader { geo in // 막대가 차지하는 실제 크기를 알기 위해 사용
            let h = geo.size.height
            ZStack(alignment:.bottom) {
                RoundedRectangle(cornerRadius: 8) // 배경
                    .fill(Color.gray.opacity(0.8))
                
                Rectangle() // 목표 범위 띠(파란색)
                    .fill(Color.green.opacity(0.8))
                    .frame(height: h * (manager.targetMax - manager.targetMin))
                    .offset(y: -h * manager.targetMin)
                
                RoundedRectangle(cornerRadius: 8)// 현재 게이지(노란색으로)
                    .fill(Color.yellow) //게이지 올라갈 때 하늘색으로
                    .frame(height: h * manager.gauge) //게이지 비율만큼 표현
            }
        }
        .frame(width: 50, height: 500) //게이지바 크기 조정
    }
    
    //코리카멘 거미줄 버전에 따라 매핑할 수 있도록 함수 추가
    private func webImageName(for index: Int) -> String {
        switch index {
            case 5: return "CoffinBody"
            case 4: return "Web4"
            case 3: return "Web3"
            case 2: return "Web2"
            case 1: return "Web1"
        default: return "CoffinBody"
    }
}
    
    var body: some View {
        ZStack{
            Image("Stage3Background")
                .resizable()
                .scaledToFill() //화면 꽉 채우기
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
                .overlay(alignment: .trailing) { // 오른쪽 고정 시키기
                    if manager.scene == .removingWeb {
                        VStack{
                            gaugeBar // scene2일 때 게이지바 추가
                                .padding(.trailing, 30)
                            Text("게이지: \(Int(manager.gauge * 100))%")
                                .foregroundStyle(Color.white.opacity(0.8))
                            Text("성공: \(manager.successCount)/\(manager.requiredSuccessCount)   거미줄: \(manager.webLayerIndex)겹")
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                    }
                }
                .overlay(alignment:.bottomTrailing) { // 마찬가지로 우측 하단에 고정
                    if manager.scene == .removingWeb { // 테스트용으로 거미줄 제거 단계에서만 보이도록 설정 
                        HStack{
                            Button("클리어 → 다음", action: onClear).buttonStyle(.borderedProminent)
                            Button("실패(테스트)", role: .destructive, action: onFail)
                        }
                        .padding()
                    }
                    
                }
            
            
            VStack(spacing: 20) {
                Text("스테이지 3 · 관 열기 & 거미줄 제거").font(.largeTitle).bold()
                    .foregroundColor(.white)
                // Text("노튼 담당 — 여기에 게임 구현").foregroundStyle(.secondary)
                Text("남은 시간: \(Int(timer.remaining))초").monospacedDigit()
                    .foregroundStyle(Color.red.opacity(0.8))
                    .monospacedDigit() //숫자만 일정한 고정폭을 갖도록 조정
                
                Spacer()
                
                //scene 전한 구조로 정리
                switch manager.scene {
                case .openingLid:
                    // Scene1 — 관 (드래그로 뚜껑 열기)
                    SpriteView(scene: coffinScene, options: [.allowsTransparency])
                        .frame(width:300, height: 600)
                    Text("뚜껑을 옆으로 밀어보세요 (\(Int(manager.lidProgress * 100))%)")
                        .foregroundStyle(Color.white.opacity(0.8))
                    
                case .removingWeb:
                    // Scene2 — 거미줄 게이지 (기존)
                    ZStack {
                        Image(webImageName(for: manager.webLayerIndex)) //단계에 맞는 거미줄 이미지 표시, webLayerIndex가 바뀌면 자동으로 이미지 교체.
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 560) // 관 크기 맞춤
                        
                        Image(webImageName(for: manager.webLayerIndex + 1))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 560) // 관 크기 맞춤
                            .blur(radius: 2 * wipeProgress) //걷히며 흐려지도록 
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color:.clear, location: 0),
                                        .init(color: .clear, location: max(0, wipeProgress - 0.15)),
                                        .init(color: .black, location: min(1, wipeProgress + 0.15)),
                                        .init(color: .black, location: 1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .offset(x: 0, y: 20)
                        Text("게이지: \(Int(manager.gauge * 100))%")
                            .opacity(1.0)
                        Text("성공: \(manager.successCount)/\(manager.requiredSuccessCount)   거미줄: \(manager.webLayerIndex)겹")
                            .opacity(1.0)
                  
                    
                }
            }
            // 씬이 사라질때의 색 지정
            Color.black
                .ignoresSafeArea()
                .opacity(fadeOpacity)
                .allowsHitTesting(false) //조작 방해 x
        }
        .padding(.leading, -10)
        .onAppear { timer.start() }
        .onChange(of: timer.isTimeOver) { _, over in if over { onFail() } }
        
        // MARK: - Scene#1 관련 기믹
        .onChange(of: pencil.state.isTouching){ _, touching in
            if !touching { // 손 뗐을 때
                manager.endLidDrag() // 열림 or 복귀 판정
                dragStartX = nil // 시작점 초기화
            }
        }
        .onChange(of: pencil.state.location) {_, loc in // 위치가 바뀔 때마다 실행
            guard let loc else { return }
            if dragStartX == nil { dragStartX = loc.x } // 첫 접촉 시, 현재 x를 시작점으로 기억하도록 설정
            let moved = loc.x - dragStartX! // 이동 거리(시작점 대비 이동량 체크)
            manager.updateLid(progress: Double(moved / dragRequiredDistance)) // 진행도 업데이트
        }
        .onChange(of: manager.lidProgress) {_, p in
            coffinScene.moveLid(progress: p) //진행도가 바뀌면 뚜껑이 이동되도록
        }
        
        .onChange(of: manager.scene) {_, _ in
            withAnimation(.easeIn(duration: 0.3)) {fadeOpacity = 1} // scene 변경 시 fadeopacity 발동
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { //0.3초에 걸쳐 부드럽게 어두워 지도록
                withAnimation(.easeOut(duration: 0.5)) {fadeOpacity = 0} //0.5초에 걸쳐 다시 밝아지도록
            }
            
        }
        
        
        // MARK: - Scene#2 관련 기믹
        // 스퀴즈 상태에 따라 맞는 함수를 부를 수 있도록 추가
        .onChange(of: pencil.state.squeezePhase){ _, phase in
            switch phase {
            case .began, .changed: manager.beginSqueeze() // 스퀴즈 시작 + 누르기 : 게이지 증가 시작
            case .ended: manager.endSqueeze() // 스퀴즈 종료 -> 판정
            case .none: break // ignore
            }
        }
        .onChange(of: manager.isCleared) {_,cleared in
            if cleared {
                timer.stop() // 제한시간 타이머 정지
                onClear() // 다음 단계(엔딩씬)로
            }
        }
        .onChange(of: manager.successCount) {_, _ in // 성공할 때마다 successCount + 1, wipeProgress -> 1 (거미줄 사라지도록)
            wipeProgress = 0
            withAnimation(.easeInOut(duration: 0.6)) {
                wipeProgress = 1
            }
        }
        .sensoryFeedback(.success, trigger: manager.successCount)   // 성공 시 햅틱 피드백 -> mock 대체 후 판단 가능할 듯
    }
}


