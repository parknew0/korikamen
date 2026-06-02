//
//  MainView.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//

import SwiftUI

struct MainView: View {
    let onStart: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text("이집트 투탕카멘 유물 도굴").font(.largeTitle).bold()
            Text("메인 화면 (자리표시) — 타이틀 / 시작 메뉴")
                .foregroundStyle(.secondary)
            Button("게임 시작", action: onStart)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
