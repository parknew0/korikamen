//
//  FailView.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//
//
//  공용 실패 화면. 어떤 스테이지든 실패하면 여기로.
//

import SwiftUI

struct FailView: View {
    let stage: Int
    let onRetry: () -> Void
    let onMain: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text("실패").font(.largeTitle).bold().foregroundStyle(.red)
            Text("스테이지 \(stage) — 시간 초과 또는 조건 미달")
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("메인으로", action: onMain).buttonStyle(.bordered)
                Button("다시 시도", action: onRetry).buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
