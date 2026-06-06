//
//  CommonComponents.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/5/26.
//  해당 파일에는 저희가 공통적으로 관리해야 할 컴포넌트를 넣으면 됩니다!
// 사용시 : TimerHUDView(remaining: 스테이지별 시간 , tint: .색, imageName: "올린 이미지이름")

import Foundation
import SwiftUI
import AVFoundation //사운드 파일 저장용





//타이머 컴포넌트

enum TickSound {
    static var player: AVAudioPlayer?
    static func play() {
        guard let url = Bundle.main.url(forResource: "tick", withExtension: "m4a") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
    static func stop() {
        player?.stop()
        player = nil
    }
}
// 사용시 : TimerHUDView(remaining: 스테이지별 시간  normalImage: , warningImage: ) <- 해보고 문제 있으면 말해주세요
struct TimerHUDView: View {
    
    let remaining : Double //스테이지별 제한 시간
    var tint: Color = .white // 평상시 글자색
    var warningTint : Color = .red //경고시 글자색
    var normalImage : String // 평상시 이미지
    var warningImage : String // 15초 이하시 이미지
    var warningThreshold: Double = 16 // 경고 기준
    
    private var isWarning: Bool { //15초 이하 + 0 초과면 경고
        remaining <= warningThreshold && remaining > 0
    }
    
    // 초 → "분:초" 형식 (예: 90 → "1:30")
    private func timeText(_ seconds: Int) -> String {
        let m = seconds / 60          // 분
        let s = seconds % 60          // 초
        return String(format: "%d:%02d", m, s)   // 1:05 처럼 초는 두 자리
    }
    
    
    var body: some View {
        ZStack{
            Image(isWarning ? warningImage : normalImage) // 다른 스테이지에 맞게 수정
                .resizable()
                .frame(width: 200, height: 70)
            Text(timeText(Int(remaining)))
                .font(Font.custom("NovaMono-Regular", size: 50))
                .foregroundStyle(isWarning ? warningTint : tint) //시간 임박시 빨강
                .offset(x: 25)
        }
        .onChange(of: isWarning) { _, warning in
            if isWarning { //iswarning이 켜지는 순간
                TickSound.play() //1회 재생
            }
        }
        .onDisappear{TickSound.stop()} //타이머가 사라지면 소리 정지되도록
        
    }
}

struct WarningBorderView: View { //15초 이하일 시 발동되는 경고 효과
    let isWarning: Bool
    @State private var pulse: Double = 0 //반복
    
    init(isWarning: Bool) {
        self.isWarning = isWarning
    }
    
    var body: some View {
        RadialGradient(
            colors: [.clear, .red.opacity(0.7)],
            center:.center,
            startRadius: 300,
            endRadius: 800
        )
        .ignoresSafeArea()
        .allowsHitTesting(false) //조작 방해 x
        .opacity(isWarning ? pulse : 0) //경고 아니면 보이지 않도록
        .onChange(of: isWarning) { _,warning in
            if warning {
                withAnimation(.easeInOut(duration:0.6).repeatForever(autoreverses: true)) {
                    pulse = 1
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {pulse = 0}
            }
        }
    }
}
#Preview {
    TimerHUDView(remaining: 90, normalImage: "Stage3Timer", warningImage: "Stage3Timer")
}
