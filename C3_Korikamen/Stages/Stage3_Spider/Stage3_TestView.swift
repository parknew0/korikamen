//
//  Stage3_TestView.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/4/26.
//

import SwiftUI
import Combine

struct Stage3_TestView: View {
    @StateObject private var timer = CountdownTimer(duration: 90)
    
    // 초 → "분:초" 형식 (예: 90 → "1:30")
    private func timeText(_ seconds: Int) -> String {
        let m = seconds / 60          // 분
        let s = seconds % 60          // 초
        return String(format: "%d:%02d", m, s)   // 1:05 처럼 초는 두 자리
       }
    var body: some View {
        ZStack{
            Image("Stage3tTimer")
                .resizable()
                .frame(width: 200, height: 70)
            
            Text(timeText(Int(timer.remaining)))
                .font(.custom("NovaMono-Regular", size: 50))
                .foregroundStyle(Color.red)
                .offset(x: 25, y: 0)
        }
            
    }
}

#Preview {
    Stage3_TestView()
}

