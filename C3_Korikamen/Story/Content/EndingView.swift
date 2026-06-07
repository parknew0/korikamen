//
//  EndingView.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//  엔딩뷰 -> 탭 시 총 플레이 시간과 함께 메인 화면으로 이동

import SwiftUI
import Combine

struct EndingView: View {
    let onReplay: () -> Void //엔딩이 끝났을 때 실행할 동작 -> game.advance
    // 총 플레이타임을 보여주려면 @EnvironmentObject var game: GameManager 추가해 game.totalPlayTime 사용
    
    @EnvironmentObject var game: GameManager //총 플레이타임 game.totalPlayTime 사용
    @StateObject private var player: StoryPlayer // 시나리오 컷 관리
    @State private var pulse = false      // 뷰 프로퍼티에 추가
    
    init(onReplay: @escaping () -> Void) { // 마지막 터치시 홈으로 돌아가도록
        self.onReplay = onReplay
        _player = StateObject(wrappedValue: StoryPlayer(pages: endingStory, onFinish: onReplay))
    }
    
    
    var body: some View {
        ZStack {
            StoryView(player: player)
            
            if player.index == endingStory.count - 1  {//마지막 컷이면
                ZStack {
                    playTimeBadge //총 플레이 시간이 나오도록
                        .allowsHitTesting(false)   // 탭은 스토리뷰가 받도록 통과
                    
                    
                    Text("계속하려면 화면을 탭하세요")
                        .offset(x: 350, y: 50)
                        .font(Font.custom("NovaMono-Regular", size: 20))
                        .foregroundStyle(Color.white)
                        .opacity(pulse ? 1.0 : 0.3) //희미해졌다가 선명해지는 연출 추가
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)){pulse = true}
                        }
                }
              
            }
        }
    }
    private var playTimeBadge: some View {
        VStack(spacing: 8) {
            Text("총 클리어 시간").font(.headline)
            Text(timeText(game.totalPlayTime))
                .font(Font.custom("NovaMono-Regular", size: 44))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal,20).padding(.vertical, 18)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func timeText(_ seconds: Double) -> String {
        let s = Int(seconds)
        return String(format: "%d분 %02d초", s / 60, s % 60)
    }
}

