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
    @StateObject private var timer = CountdownTimer(duration: 180)   // 3분 (기획값)

    var body: some View {
        VStack(spacing: 20) {
            Text("스테이지 2 · 관 자물쇠 따기").font(.largeTitle).bold()
            Text("남은 시간: \(Int(timer.remaining))초").monospacedDigit()
            
          //  LockGaugeView {
            //    timer.stop()
            //    onClear()
            // }
            HStack {
                Button("클리어 → 다음", action: onClear).buttonStyle(.borderedProminent)
                Button("실패(테스트)", role: .destructive, action: onFail)
            }
            HStack{
                Button("클리어 → 다음", action: onClear).buttonStyle(.borderedProminent)
                Button("실패(테스트)", role: .destructive, action: onFail)
            }
        }
        .padding()
        .onAppear { timer.start() }
        .onChange(of: timer.isTimeOver) { _, over in if over { onFail() } }
    }
}
