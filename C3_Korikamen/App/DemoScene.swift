//
//  DemoScene.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//
//  SpriteKit이 SwiftUI 안에서 도는지 확인용 데모 씬.
//

import SpriteKit

final class DemoScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .systemIndigo
        let box = SKSpriteNode(color: .systemTeal,
                               size: CGSize(width: 80, height: 80))
        box.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(box)
        box.run(.repeatForever(.rotate(byAngle: .pi, duration: 1.5)))  // 빙글빙글
    }
}
