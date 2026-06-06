//
//  OverlayLayer.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/6/26.
//  오버레이 관련 효과들을 해당 파일에 정리

import Foundation
import SwiftUI

struct OverlayLayer: View {
    let overlay: StoryOverlay

    @State private var appeared = false   // 등장 완료
    @State private var floating = false   // 둥둥 떠다니도록

    var body: some View {
        Image(overlay.image)
            .resizable()
            .scaledToFit()
            // 위치 (UnitPoint → 화면 정렬)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            // 등장 전: 위로 올라가 있고 투명 → 등장 후: 제자리
            .offset(y: appeared ? floatOffset : -300)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                // 1) appearDelay 뒤 슬라이드 등장
                DispatchQueue.main.asyncAfter(deadline: .now() + overlay.appearDelay) {
                    withAnimation(.easeOut(duration: 0.8)) { appeared = true }
                    // 2) 등장 끝나면 둥둥 시작
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        floating = true
                    }
                }
            }
    }

    // 둥둥 오프셋 (등장 후에만)
    private var floatOffset: CGFloat { floating ? -15 : 15 }

    // UnitPoint → Alignment 변환
    private var alignment: Alignment {
        switch overlay.position {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }
}
