//
//  Stage1HitTester.swift
//  C3_Korikamen
//
//  Stage1의 '알파 기반 판정' 전담. 화면 좌표 p가
//   - 어느 살아있는 돌 위인지(topLiveRockIndex),
//   - 깨서 드러난 관(실패 지대)인지(coffinDanger)
//  를 픽셀 투명도(AlphaMask)로 답한다.
//  렌더링·연출은 모름. 씬이 노드/마스크/'원래 중심'과 조각 클리어 여부만 주입한다.
//

import SpriteKit

final class Stage1HitTester {

    private let pieceNodes: [SKSpriteNode]
    private let rockMasks: [Int: AlphaMask]
    private let coffinNode: SKSpriteNode?
    private let coffinMask: AlphaMask?
    private let alphaThreshold: UInt8           // 돌 판정 문턱
    private let coffinAlphaThreshold: UInt8     // 관 판정 문턱(더 높음 = 관 위험영역 축소 → 여유)
    private let isCleared: (Int) -> Bool        // 조각 클리어 여부(매니저 위임)
    private var centers: [CGPoint]              // 흔들림 무시한 '원래 중심'

    init(pieceNodes: [SKSpriteNode],
         rockMasks: [Int: AlphaMask],
         coffinNode: SKSpriteNode?,
         coffinMask: AlphaMask?,
         centers: [CGPoint],
         alphaThreshold: UInt8,
         coffinAlphaThreshold: UInt8,
         isCleared: @escaping (Int) -> Bool) {
        self.pieceNodes = pieceNodes
        self.rockMasks = rockMasks
        self.coffinNode = coffinNode
        self.coffinMask = coffinMask
        self.centers = centers
        self.alphaThreshold = alphaThreshold
        self.coffinAlphaThreshold = coffinAlphaThreshold
        self.isCleared = isCleared
    }

    func updateCenters(_ c: [CGPoint]) { centers = c }

    /// 파편 색(불투명 픽셀 평균색). 에셋 없으면 식별용 임시색.
    func rockColor(_ id: Int) -> SKColor {
        rockMasks[id]?.color ?? Stage1Layout.placeholderColor(id)
    }

    private func center(of i: Int) -> CGPoint {
        i < centers.count ? centers[i] : pieceNodes[i].position
    }

    // MARK: - 픽셀 판정

    /// 그 지점이 노드의 '실제 그림' 위인지(투명 모서리는 false). 마스크 없으면 사각형 전체 solid.
    /// 판정은 흔들림(shake) 전의 '원래 중심(center)' 기준 → 진동 중에도 선택이 안 흔들린다.
    private func isOpaque(_ node: SKSpriteNode, _ mask: AlphaMask?, center: CGPoint, at p: CGPoint,
                         threshold: UInt8) -> Bool {
        let s = node.xScale == 0 ? 1 : node.xScale
        let w = node.size.width, h = node.size.height
        guard w > 0, h > 0 else { return false }
        let lx = (p.x - center.x) / s        // 회전 없음 가정(이 게임은 회전 X)
        let ly = (p.y - center.y) / s
        guard abs(lx) <= w / 2, abs(ly) <= h / 2 else { return false }   // 빠른 거르기
        guard let mask = mask else { return true }                       // 플레이스홀더
        let px = Int((lx + w / 2) / w * CGFloat(mask.width))
        let py = Int((1 - (ly + h / 2) / h) * CGFloat(mask.height))      // 이미지 y는 위가 0
        guard let a = mask.alpha(px, py) else { return false }
        return a >= threshold
    }

    /// 그 지점에서 '아직 안 깨진' 돌 중 맨 위(z 최고). 알파로 실제 그림 위만 인정.
    func topLiveRockIndex(at p: CGPoint) -> Int? {
        var best: Int?
        for i in pieceNodes.indices where !isCleared(i) {
            guard isOpaque(pieceNodes[i], rockMasks[i], center: center(of: i), at: p,
                           threshold: alphaThreshold) else { continue }
            if best == nil || pieceNodes[i].zPosition > pieceNodes[best!].zPosition { best = i }
        }
        return best
    }

    /// 그 지점에 관의 '핵심(높은 알파)' 픽셀이 있는지. 문턱을 높여 가장자리 여유를 둔다.
    private func coffinPixel(at p: CGPoint) -> Bool {
        guard let node = coffinNode else { return false }
        return isOpaque(node, coffinMask, center: node.position, at: p, threshold: coffinAlphaThreshold)
    }

    /// 시작 시 '돌(아무 조각이나)'이 그 지점을 덮고 있었는가. (깬 조각도 포함 → 원래 덮였던 자리 판별)
    private func wasCoveredByRock(at p: CGPoint) -> Bool {
        for i in pieceNodes.indices {
            if isOpaque(pieceNodes[i], rockMasks[i], center: center(of: i), at: p,
                        threshold: alphaThreshold) { return true }
        }
        return false
    }

    /// 실패 지대: 관 핵심 픽셀 + 원래 돌이 덮었던 자리 + 지금은 산 돌 없음(=깨서 노출됨).
    /// 처음부터 있던 조각 사이 '틈'은 안전. 관 가장자리도 알파 문턱 덕분에 여유.
    func coffinDanger(at p: CGPoint) -> Bool {
        coffinPixel(at: p) && wasCoveredByRock(at: p) && topLiveRockIndex(at: p) == nil
    }
}
