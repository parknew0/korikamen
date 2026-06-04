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
    private let rockTouchTolerance: CGFloat     // 돌 터치 여유(화면 포인트). 실루엣 바깥 확장.
    private let isCleared: (Int) -> Bool        // 조각 클리어 여부(매니저 위임)
    private var centers: [CGPoint]              // 흔들림 무시한 '원래 중심'

    init(pieceNodes: [SKSpriteNode],
         rockMasks: [Int: AlphaMask],
         coffinNode: SKSpriteNode?,
         coffinMask: AlphaMask?,
         centers: [CGPoint],
         alphaThreshold: UInt8,
         coffinAlphaThreshold: UInt8,
         rockTouchTolerance: CGFloat,
         isCleared: @escaping (Int) -> Bool) {
        self.pieceNodes = pieceNodes
        self.rockMasks = rockMasks
        self.coffinNode = coffinNode
        self.coffinMask = coffinMask
        self.centers = centers
        self.alphaThreshold = alphaThreshold
        self.coffinAlphaThreshold = coffinAlphaThreshold
        self.rockTouchTolerance = rockTouchTolerance
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
    /// - 렌더된 실제 바운딩은 `node.frame`(스케일 반영, SpriteKit이 보증)을 쓰고, 흔들림 면역을 위해
    ///   크기만 가져와 '원래 중심(center)'에 다시 맞춘다 → 수동 size×scale 계산의 오차/이중 스케일 제거.
    /// - tolerance(화면 포인트)>0이면 실루엣을 그만큼 바깥으로 넓혀(틈/반투명 가장자리 보정) 판정.
    private func isOpaque(_ node: SKSpriteNode, _ mask: AlphaMask?, center: CGPoint, at p: CGPoint,
                         threshold: UInt8, tolerance: CGFloat = 0) -> Bool {
        let f = node.frame                                  // 렌더된 실제 크기(스케일 반영). 회전 없음 가정.
        let halfW = f.width / 2, halfH = f.height / 2
        guard halfW > 0, halfH > 0 else { return false }
        let dx = p.x - center.x, dy = p.y - center.y        // 중심 대비 화면(씬) 오프셋
        guard abs(dx) <= halfW + tolerance, abs(dy) <= halfH + tolerance else { return false }  // 빠른 거르기
        guard let mask = mask else { return true }          // 플레이스홀더는 사각형 전체

        // 화면 오프셋(dx,dy)을 텍스처 픽셀로 변환(렌더 폭 기준이라 스케일 자동 보정).
        func opaque(at ox: CGFloat, _ oy: CGFloat) -> Bool {
            let u = (dx + ox + halfW) / f.width             // 0..1 좌→우
            let v = 1 - (dy + oy + halfH) / f.height        // 0..1 위→아래(이미지 y는 위가 0)
            let px = Int(u * CGFloat(mask.width)), py = Int(v * CGFloat(mask.height))
            guard let a = mask.alpha(px, py) else { return false }
            return a >= threshold
        }

        if opaque(at: 0, 0) { return true }                 // 정확 지점 우선
        guard tolerance > 0 else { return false }
        // 여유 반경의 8방향 샘플 → 실루엣을 화면상 등방으로 tolerance만큼 확장(틈 메움).
        let t = tolerance
        for (ox, oy) in [(-t, 0), (t, 0), (0, -t), (0, t),
                         (-t, -t), (t, -t), (-t, t), (t, t)] where opaque(at: ox, oy) {
            return true
        }
        return false
    }

    /// 그 지점에서 '아직 안 깨진' 돌 중 맨 위(z 최고). 알파로 실제 그림 위만 인정(터치 여유 포함).
    func topLiveRockIndex(at p: CGPoint) -> Int? {
        var best: Int?
        for i in pieceNodes.indices where !isCleared(i) {
            guard isOpaque(pieceNodes[i], rockMasks[i], center: center(of: i), at: p,
                           threshold: alphaThreshold, tolerance: rockTouchTolerance) else { continue }
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
