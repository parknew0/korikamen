//
//  Stage2View.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//

import SwiftUI


struct Stage2View: View {
    let onClear: () -> Void
    let onFail: () -> Void
    @StateObject private var timer = CountdownTimer(duration: 90)   // 1분 30초로 수정

    var body: some View {
      ZStack {
            background
              .overlay(alignment: .bottomTrailing) { bottomButtons } // 우측 하단 테스트 버튼
          
            WarningBorderView(isWarning: isTimeWarning)     // 타임임박 시 붉은 효과

            VStack(spacing: 20) {
                Spacer()        // 펜슬 인식범위 캔버스 미세조정에 시간을 더 쏟지 않기 위한 몸부림
                Spacer()
                
                LockGaugeView {
                    timer.stop()
                    onClear()
                 }
                                
            }
            .overlay(alignment: .top){ topHUD }
            .padding()
            .onAppear { timer.start() }
            .onChange(of: timer.isTimeOver) { _, over in if over { onFail() } }
          

            
        }
    }
    
    // 테스트에 사용하는 임시 버튼들
    private var bottomButtons: some View {
        Group {
            HStack {
                Button("클리어 → 다음", action: onClear).buttonStyle(.borderedProminent)
                Button("실패(테스트)", role: .destructive, action: onFail)
            }
        }
    }
    
    // 상단 HUD (좌측 타이틀 + 우측 타이머)
    private var topHUD: some View {
        HStack{
            // 좌측 상단 타이틀
            Image("Stage2_Title")
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
    }
    
    // 시간 임박(15초 이하) 경고 상태
    private var isTimeWarning: Bool { timer.remaining <= 15 && timer.remaining > 0 }

    
    // 배경
    private var background: some View {
        Image("Stage2Background")
            .resizable()
//            .scaledToFill() // 이상하게 이거 하면 화면이 확대되서 보여서 일단 주석처리
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}
