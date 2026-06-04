//
//  Stage1Effects.swift
//  C3_Korikamen
//
//  Stage1 타격 연출 전담: 파편(이미터) + 흔들림.
//  - 드릴: 연속 파편 + 연속 진동. 끌: 1회 버스트 파편 + 1회 흔들림.
//  - 판정/게임 로직은 모름. 씬이 "어디를, 어느 조각을, 무슨 색으로" 알려주면 연출만 한다.
//

import SpriteKit

final class Stage1Effects {

    private weak var debrisLayer: SKNode?
    private let pieceNodes: [SKSpriteNode]
    private var centers: [CGPoint]                 // 흔들림 복귀 기준(원래 위치)
    private let chipTexture: SKTexture?            // 파편용 칩 텍스처(1회 생성 후 재사용)

    private var drillEmitter: SKEmitterNode?       // 드릴 연속 파편(있는 동안 birthRate만 토글)
    private var drillShakeID: Int?                 // 지금 드릴 진동 중인 조각

    init(view: SKView, debrisLayer: SKNode, pieceNodes: [SKSpriteNode], centers: [CGPoint]) {
        self.debrisLayer = debrisLayer
        self.pieceNodes = pieceNodes
        self.centers = centers
        self.chipTexture = Stage1Effects.makeChipTexture(in: view)
    }

    func updateCenters(_ c: [CGPoint]) { centers = c }

    private func center(of i: Int) -> CGPoint {
        i < centers.count ? centers[i] : pieceNodes[i].position
    }

    // MARK: - 파편

    /// 들쭉날쭉한 작은 돌칩 텍스처를 1회만 만들어 모든 파편이 공유(생성 비용 절감).
    private static func makeChipTexture(in view: SKView) -> SKTexture? {
        let path = CGMutablePath()
        let pts = [CGPoint(x: -3, y: -2), CGPoint(x: 2, y: -3),
                   CGPoint(x: 4, y: 1), CGPoint(x: 0, y: 4), CGPoint(x: -3, y: 2)]
        path.addLines(between: pts)
        path.closeSubpath()
        let shape = SKShapeNode(path: path)
        shape.fillColor = .white      // 색은 파편에서 입힘(colorBlend)
        shape.strokeColor = .clear
        return view.texture(from: shape)
    }

    /// 파편 이미터 1개를 설정해서 반환(드릴=연속, 끌=버스트 공용).
    private func makeDebrisEmitter(color: SKColor) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = chipTexture
        e.particleColor = color
        e.particleColorBlendFactor = 1
        e.particleLifetime = 0.5
        e.particleLifetimeRange = 0.3
        e.particleSpeed = 150
        e.particleSpeedRange = 90
        e.emissionAngleRange = .pi * 2          // 사방으로 튐
        e.yAcceleration = -700                  // 중력 → 떨어짐
        e.particleScale = 0.9
        e.particleScaleRange = 0.6
        e.particleScaleSpeed = -1.0             // 점점 작아짐
        e.particleAlpha = 1
        e.particleAlphaSpeed = -1.4             // 점점 사라짐
        e.particleRotationRange = .pi * 2
        e.particleRotationSpeed = 6
        e.targetNode = debrisLayer              // 파편이 돌 위 레이어에 제자리로 흩어지게
        return e
    }

    /// 끌 타격: 한 번에 파편 버스트.
    func burstDebris(at p: CGPoint, color: SKColor) {
        guard let layer = debrisLayer else { return }
        let e = makeDebrisEmitter(color: color)
        e.position = p
        e.numParticlesToEmit = 12
        e.particleBirthRate = 600
        layer.addChild(e)
        e.run(.sequence([.wait(forDuration: 1.0), .removeFromParent()]))   // 다 뿜고 정리
    }

    /// 드릴 연속 파편: 이미터 1개를 켜둔 채 위치/색만 갱신, 멈추면 birthRate 0.
    func drillDebris(at p: CGPoint, color: SKColor) {
        if drillEmitter == nil {
            let e = makeDebrisEmitter(color: color)
            e.numParticlesToEmit = 0            // 무한(연속)
            debrisLayer?.addChild(e)
            drillEmitter = e
        }
        drillEmitter?.position = p
        drillEmitter?.particleColor = color
        drillEmitter?.particleBirthRate = 70
    }

    func stopDrillDebris() { drillEmitter?.particleBirthRate = 0 }

    // MARK: - 흔들림

    /// 끌: 한 번 툭 흔들고 제자리로(되돌아오는 시퀀스라 위치 안 틀어짐).
    func shakeOnce(id: Int) {
        let a: CGFloat = 3
        pieceNodes[id].run(.sequence([
            .moveBy(x: a, y: -a * 0.5, duration: 0.03),
            .moveBy(x: -a * 2, y: a, duration: 0.05),
            .moveBy(x: a, y: -a * 0.5, duration: 0.03)
        ]), withKey: "shake")
    }

    /// 드릴: 해당 조각에 연속 진동(repeatForever). 다른 조각으로 옮기면 이전 건 멈춤.
    func startDrillShake(id: Int) {
        guard drillShakeID != id else { return }
        stopDrillShake()
        drillShakeID = id
        let j: CGFloat = 1.8
        let cycle = SKAction.sequence([
            .moveBy(x: j, y: j * 0.6, duration: 0.02),
            .moveBy(x: -j * 2, y: -j * 1.2, duration: 0.04),
            .moveBy(x: j, y: j * 0.6, duration: 0.02)
        ])
        pieceNodes[id].run(.repeatForever(cycle), withKey: "drillShake")
    }

    func stopDrillShake() {
        if let id = drillShakeID {
            pieceNodes[id].removeAction(forKey: "drillShake")
            pieceNodes[id].position = center(of: id)   // 잔여 오프셋 제거
        }
        drillShakeID = nil
    }
}
