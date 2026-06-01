//
//  C3_KorikamenApp.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//
//  앱 진입점 (SwiftUI 라이프사이클)
//

import SwiftUI

@main
struct C3_KorikamenApp: App {
    // 앱 전체가 공유하는 펜슬 입력(1단계 계약). 여기서 한 번 생성·소유.
    @StateObject private var pencil = PencilInput()
    // 3단계에서 GameManager도 여기 추가 예정:
    // @StateObject private var game = GameManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pencil)      // 하위 어디서든 @EnvironmentObject로 사용
                // .environmentObject(game)     // 3단계에서 함께 주입
        }
    }
}
