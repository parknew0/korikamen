//
//  ContentView.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    // SpriteKit 장면은 한 번만 만들어 들고 있는다(매 렌더마다 재생성 방지).
    @State private var scene = DemoScene(size: CGSize(width: 300, height: 300))

    var body: some View {
        VStack(spacing: 16) {
            Text("C3 Korikamen")
                .font(.largeTitle).bold()
            Text("SwiftUI 셸 위에서 동작 — 아래 박스는 SpriteKit이 그립니다")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // 👇 게임은 그대로! SpriteKit 장면을 SwiftUI 안에 박아 넣는 예시.
            SpriteView(scene: scene)
                .frame(width: 300, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
