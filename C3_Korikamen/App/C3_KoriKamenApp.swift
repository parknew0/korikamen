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
struct C3_KoriKamenApp: App {
    @StateObject private var pencil = PencilInput()
    @StateObject private var game = GameManager()      // ← 3단계에서 추가

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pencil)
                .environmentObject(game)               // ← 하위 어디서든 game 사용
        }
    }
}

