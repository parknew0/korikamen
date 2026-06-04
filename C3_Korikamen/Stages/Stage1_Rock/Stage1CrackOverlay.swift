//
//  Stage1CrackOverlay.swift
//  C3_Korikamen
//
//  돌 조각 위에 얹는 '균열 오버레이'의 렌더링/상태 관리.
//  - 절차적 균열 알고리즘(모양·자람)은 Stage1Crack.swift(CrackPattern)가 담당.
//  - 이 타입은 그 결과를 SKShapeNode(밝은선+어두운선)로 그리고, 손상도에 맞춰 갱신한다.
//  돌 모양 밖으로 새지 않도록 SKCropNode로 조각 텍스처에 클리핑한다.
//

import SpriteKit

final class Stage1CrackOverlay {

    private var dark: [Int: SKShapeNode] = [:]      // 어두운 균열선
    private var glow: [Int: SKShapeNode] = [:]      // 밝은 하이라이트(어떤 돌색에도 보이게)
    private var patterns: [Int: [Crack]] = [:]
    private var bucket: [Int: Int] = [:]            // 손상 단계 캐시(매 프레임 재생성 방지)

    /// 돌 모양에 클리핑되는 균열 오버레이(밝은 선 + 어두운 선)를 조각 위에 얹는다.
    func attach(to node: SKSpriteNode, id: Int, maskSprite: SKSpriteNode) {
        maskSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        maskSprite.position = .zero
        let crop = SKCropNode()
        crop.maskNode = maskSprite         // 돌 그림이 있는 픽셀에서만 균열이 보임
        crop.zPosition = 1                 // 돌 텍스처 위

        let g = SKShapeNode()              // 밝은 하이라이트(아래)
        g.strokeColor = SKColor(white: 1, alpha: 0.35)
        g.lineWidth = 4
        g.lineCap = .round
        g.lineJoin = .round

        let d = SKShapeNode()              // 어두운 균열(위)
        d.strokeColor = SKColor(white: 0, alpha: 0.85)
        d.lineWidth = 2
        d.lineCap = .round
        d.lineJoin = .round

        crop.addChild(g)
        crop.addChild(d)
        node.addChild(crop)

        glow[id] = g
        dark[id] = d
        patterns[id] = CrackPattern.generate(seed: UInt64(id + 1),
                                              width: node.size.width,
                                              height: node.size.height)
        bucket[id] = -1
    }

    /// 손상도에 맞춰 균열 경로/굵기 갱신(단계가 바뀔 때만 재생성).
    func update(id: Int, damage: Double) {
        let b = Int(damage * 24)
        guard bucket[id] != b else { return }
        bucket[id] = b
        guard let pattern = patterns[id] else { return }
        let path = CrackPattern.path(pattern, damage: damage)
        dark[id]?.path = path
        glow[id]?.path = path
        dark[id]?.lineWidth = 1.5 + CGFloat(damage) * 2.0   // 손상 클수록 굵게
        glow[id]?.lineWidth = 3.5 + CGFloat(damage) * 2.5
    }
}
