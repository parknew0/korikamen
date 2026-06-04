//
//  Stage1Scene+Debug.swift
//  C3_Korikamen
//
//  Stage1Scene의 '디버그 전용' 도구 모음 — 릴리스 빌드에서 완전히 제외된다(#if DEBUG).
//   - 터치맵   : 화면을 실제 판정 함수로 샘플링해 색칠(초록=돌, 빨강=노출된 관).
//   - 히트박스 : 살아있는 돌/관 사각범위 + 터치점 오버레이.
//   - 배치모드 : 조각 드래그로 좌표 잡기.
//   - dump     : 잡은 좌표/변환을 소스에 붙여넣을 형태로 콘솔 출력.
//
//  씬 본체(Stage1Scene)는 게임 코드만 남기고, 디버그 부피는 여기로 격리한다.
//

#if DEBUG
import SpriteKit

extension Stage1Scene {

    // MARK: - 터치맵

    func removeTouchMap() { touchMapNode?.removeFromParent(); touchMapNode = nil }

    /// 화면 전체를 실제 판정 함수로 샘플링해 색칠한 오버레이를 만든다.
    /// 초록=돌 깎임, 빨강=깨서 노출된 관(실패). 토글 시 1회 생성(돌 깬 뒤 다시 토글하면 갱신).
    func buildTouchMap() {
        removeTouchMap()
        guard let hit = hitTester else { return }
        let W = 256, H = 192                       // 저해상 샘플(디버그용, 1회만)
        var buf = [UInt8](repeating: 0, count: W * H * 4)
        for j in 0..<H {
            let sy = size.height - (CGFloat(j) + 0.5) / CGFloat(H) * size.height
            for i in 0..<W {
                let sx = (CGFloat(i) + 0.5) / CGFloat(W) * size.width
                let p = CGPoint(x: sx, y: sy)
                let idx = (j * W + i) * 4
                if hit.topLiveRockIndex(at: p) != nil {        // 초록(안전)
                    setPixel(&buf, idx, r: 40, g: 220, b: 90, a: 120)
                } else if hit.coffinDanger(at: p) {            // 빨강(실패)
                    setPixel(&buf, idx, r: 235, g: 45, b: 45, a: 140)
                }
            }
        }
        guard let ctx = CGContext(data: &buf, width: W, height: H,
                                  bitsPerComponent: 8, bytesPerRow: W * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let cg = ctx.makeImage() else { return }
        let tex = SKTexture(cgImage: cg)
        tex.filteringMode = .nearest
        let node = SKSpriteNode(texture: tex)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.size = size
        node.zPosition = 200
        addChild(node)
        touchMapNode = node
    }

    /// premultipliedLast 버퍼에 색 기록(RGB는 알파 곱).
    private func setPixel(_ buf: inout [UInt8], _ idx: Int, r: Int, g: Int, b: Int, a: Int) {
        buf[idx]     = UInt8(r * a / 255)
        buf[idx + 1] = UInt8(g * a / 255)
        buf[idx + 2] = UInt8(b * a / 255)
        buf[idx + 3] = UInt8(a)
    }

    // MARK: - 히트박스 + 선택 표시

    /// 현재 지점에서 뭐가 잡히는지(돌 index 또는 노출된 관) 계산해 기록 + 콘솔 출력.
    func debugUpdatePick(at p: CGPoint) {
        let picked = hitTester?.topLiveRockIndex(at: p)
        lastPicked = picked
        lastCoffinHit = (picked == nil) && (hitTester?.coffinDanger(at: p) ?? false)
        if showHitboxes {
            if let i = picked { print("👉 터치 → 돌 rock_\(String(format: "%02d", i)) 선택") }
            else if lastCoffinHit { print("👉 터치 → 노출된 관(실패 지점)") }
            else { print("👉 터치 → 아무것도 없음(빈 공간)") }
        }
    }

    /// 디버그 오버레이: 살아있는 돌 사각범위(선택=초록), 관 범위(노출 닿음=빨강), 터치점(노랑).
    func renderHitboxes() {
        hitboxLayer?.removeFromParent()
        hitboxLayer = nil
        guard showHitboxes else { return }

        let layer = SKNode()
        layer.zPosition = 900

        if let c = coffinNode {
            layer.addChild(outline(rect: c.calculateAccumulatedFrame(),
                                   color: lastCoffinHit ? .red : SKColor.purple,
                                   label: "관", at: c.position))
        }
        if let m = manager {
            for i in pieces.indices where !m.pieces[i].isCleared {
                let color: SKColor = (i == lastPicked) ? .green : .white
                layer.addChild(outline(rect: pieces[i].frame,
                                       color: color, label: "\(i)", at: pieces[i].position))
            }
        }
        if let p = activeTouch {
            let dot = SKShapeNode(circleOfRadius: 8)
            dot.position = p
            dot.fillColor = .yellow
            dot.strokeColor = .black
            layer.addChild(dot)
        }
        addChild(layer)
        hitboxLayer = layer
    }

    private func outline(rect: CGRect, color: SKColor, label: String, at center: CGPoint) -> SKNode {
        let box = SKShapeNode(rect: rect)
        box.strokeColor = color
        box.lineWidth = 2
        box.fillColor = .clear
        let tag = SKLabelNode(text: label)
        tag.fontSize = 18
        tag.fontColor = color
        tag.position = center
        tag.verticalAlignmentMode = .center
        let g = SKNode()
        g.addChild(box)
        g.addChild(tag)
        return g
    }

    // MARK: - 배치 모드(조각 드래그)

    func debugBeginDrag(at p: CGPoint) {
        dragging = pieces.filter { $0.frame.contains(p) }.max { $0.zPosition < $1.zPosition }
        if let d = dragging { dragOffset = CGSize(width: p.x - d.position.x, height: p.y - d.position.y) }
    }

    func debugMoveDrag(at p: CGPoint) {
        guard let d = dragging else { return }
        d.position = CGPoint(x: p.x - dragOffset.width, y: p.y - dragOffset.height)
    }

    func debugEndTouch() {
        dragging = nil
        lastPicked = nil
        lastCoffinHit = false
    }

    // MARK: - 좌표 출력(배치/조정 모드)

    func dumpPositions() {
        let lines = pieces
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
            .map { String(format: "    CGPoint(x: %.1f, y: %.1f), // %@",
                          $0.position.x, $0.position.y, $0.name ?? "") }
            .joined(separator: "\n")
        print("""

        // ▼▼▼ Stage1Layout.bakedLayout 에 붙여넣기 (designSize \(Int(Stage1Layout.designSize.width))x\(Int(Stage1Layout.designSize.height)))
        static let bakedLayout: [CGPoint]? = [
        \(lines)
        ]
        // ▲▲▲

        """)
    }

    /// 조정모드에서 맞춘 무더기/관 위치·배율을 Stage1Layout 상수에 붙여넣을 형태로 출력.
    func dumpTransform() {
        print("""

        // ▼▼▼ Stage1Layout 상수에 붙여넣기 (조정모드 결과)
        static let pilePosition = CGPoint(x: \(String(format: "%.1f", pilePosition.x)), y: \(String(format: "%.1f", pilePosition.y)))
        static let pileScale: CGFloat = \(String(format: "%.3f", pileScale))
        static let coffinPosition = CGPoint(x: \(String(format: "%.1f", coffinPosition.x)), y: \(String(format: "%.1f", coffinPosition.y)))
        static let coffinScale: CGFloat = \(String(format: "%.3f", coffinScale))
        // ▲▲▲

        """)
    }
}
#endif
