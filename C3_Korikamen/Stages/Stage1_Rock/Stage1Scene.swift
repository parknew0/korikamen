//
//  Stage1Scene.swift
//  C3_Korikamen
//
//  Created by Park on 6/3/26.
//  Stage1(관 돌 부수기) SpriteKit 씬.
//
//  두 가지 모드:
//   - 플레이 모드(기본): 조각을 터치/펜슬로 깬다. 드릴=꾹 연속, 끌=툭 단발.
//     터치 판정은 '알파(픽셀)' 기반 → 돌 모양대로만 눌린다(투명한 모서리는 무시).
//     돌이 다 깨진 자리로 '맨 뒤의 관'이 드러나고, 그 노출된 관 픽셀에 닿으면 실패.
//   - 배치 모드(DEBUG 토글): 조각을 드래그해 위치를 잡고 dumpPositions로 좌표를 뽑는다.
//
//  입력 분담: 위치는 씬의 터치, 세기(pressure)는 PencilInput에서 주입(pressureProvider).
//

import SpriteKit

final class Stage1Scene: SKScene {

    /// 설계 기준 캔버스(고정). aspectFit이라 기기 해상도가 달라도 좌표가 그대로 재사용됨.
    static let designSize = CGSize(width: 1024, height: 768)
    static let pieceCount = 12

    /// 무더기 "안에서" 조각끼리의 상대 위치(배치 모드에서 dumpPositions로 뽑은 값).
    static let bakedLayout: [CGPoint]? = [
        CGPoint(x: 481.6, y: 673.9), // rock_00
        CGPoint(x: 481.7, y: 589.1), // rock_01
        CGPoint(x: 403.2, y: 606.0), // rock_02
        CGPoint(x: 581.3, y: 600.4), // rock_03
        CGPoint(x: 564.4, y: 431.3), // rock_04
        CGPoint(x: 401.2, y: 409.8), // rock_05
        CGPoint(x: 623.3, y: 330.6), // rock_06
        CGPoint(x: 562.6, y: 235.6), // rock_07
        CGPoint(x: 443.2, y: 240.2), // rock_08
        CGPoint(x: 507.9, y: 111.9), // rock_09
        CGPoint(x: 484.7, y: 48.2),  // rock_10
        CGPoint(x: 497.0, y: -40.7), // rock_11
    ]

    /// 무더기 "전체"를 통째로 옮기는 손잡이. 이 값 하나만 바꾸면 12조각이 같이 이동.
    static let clusterOffset = CGVector(dx: 0, dy: 67)

    /// 돌무더기 "뒤"에 깔리는 관 이미지. Assets에 이 이름의 png를 넣으면 자동으로 깔린다.
    static let coffinName = "coffin"
    /// 관 위치 미세 조정(돌무더기 중심 기준).
    static let coffinOffset = CGVector(dx: 0, dy: 0)
    /// 관 크기 조정(1.0 = 원본).
    static let coffinScale: CGFloat = 1.0

    /// 알파 판정 문턱(0~255). 이 값 이상이면 '실제 그림이 있는' 픽셀로 본다.
    private let alphaThreshold: UInt8 = 20

    // MARK: - 외부 연결(뷰에서 주입)

    weak var manager: Stage1GameManager?
    var pressureProvider: () -> Double = { 0 }
    var editMode = false {
        didSet { activeTouch = nil; dragging = nil }
    }

    // MARK: - 내부 상태

    private var pieces: [SKSpriteNode] = []
    private var rockMasks: [Int: AlphaMask] = [:]   // 조각별 알파 마스크(에셋 있을 때)
    private var coffinNode: SKSpriteNode?
    private var coffinMask: AlphaMask?

    private var clearedShown = Set<Int>()
    private var activeTouch: CGPoint?               // 현재 누르고 있는 지점(플레이 모드)
    private var lastUpdate: TimeInterval = 0

    // 배치 모드 드래그
    private var dragging: SKSpriteNode?
    private var dragOffset: CGSize = .zero

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .aspectFit
        backgroundColor = SKColor(white: 0.12, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        guard pieces.isEmpty else { return }   // 재진입 시 중복 생성 방지
        buildCoffin()                          // 먼저 관(뒤)
        buildPieces()                          // 그 위에 돌
    }

    // MARK: - 관(배경 레이어)

    private func buildCoffin() {
        guard let img = UIImage(named: Self.coffinName) else { return }  // png 없으면 패스
        let node = SKSpriteNode(texture: SKTexture(image: img))
        node.name = "coffin"
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = -1
        node.setScale(Self.coffinScale)
        node.position = pileCenter(extra: Self.coffinOffset)
        addChild(node)
        coffinNode = node
        coffinMask = AlphaMask(img)
    }

    private func pileCenter(extra: CGVector = .zero) -> CGPoint {
        guard let layout = Self.bakedLayout, !layout.isEmpty else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        let cx = layout.map { $0.x }.reduce(0, +) / CGFloat(layout.count)
        let cy = layout.map { $0.y }.reduce(0, +) / CGFloat(layout.count)
        return CGPoint(x: cx + Self.clusterOffset.dx + extra.dx,
                       y: cy + Self.clusterOffset.dy + extra.dy)
    }

    // MARK: - 조각 생성

    private func buildPieces() {
        for id in 0..<Self.pieceCount {
            let name = String(format: "rock_%02d", id)
            let node: SKSpriteNode
            if let img = UIImage(named: name) {
                node = SKSpriteNode(texture: SKTexture(image: img))
                rockMasks[id] = AlphaMask(img)
            } else {
                node = SKSpriteNode(color: Self.placeholderColor(id), size: CGSize(width: 110, height: 110))
                let label = SKLabelNode(text: "\(id)")
                label.verticalAlignmentMode = .center
                label.fontSize = 36
                node.addChild(label)
            }
            node.name = name
            node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            node.zPosition = CGFloat(id)                 // id 클수록 위 → 터치 우선권
            node.position = startPosition(id)
            addChild(node)
            pieces.append(node)
        }
    }

    private func startPosition(_ id: Int) -> CGPoint {
        if let layout = Self.bakedLayout, id < layout.count {
            return CGPoint(x: layout[id].x + Self.clusterOffset.dx,
                           y: layout[id].y + Self.clusterOffset.dy)
        }
        let cols = 4
        let rows = (Self.pieceCount + cols - 1) / cols
        let col = id % cols, row = id / cols
        let cellW = size.width  / CGFloat(cols + 1)
        let cellH = size.height / CGFloat(rows + 1)
        return CGPoint(x: cellW * CGFloat(col + 1),
                       y: size.height - cellH * CGFloat(row + 1))
    }

    // MARK: - 알파 기반 판정

    /// 그 지점이 노드의 '실제 그림' 위인지(투명 모서리는 false). 마스크 없으면 사각형 전체 solid.
    private func isOpaque(_ node: SKSpriteNode, _ mask: AlphaMask?, at p: CGPoint) -> Bool {
        guard node.frame.contains(p) else { return false }   // 빠른 1차 거르기
        guard let mask = mask else { return true }            // 플레이스홀더(에셋 없음)
        let lp = node.convert(p, from: self)                  // 노드 로컬(중심 기준)
        let w = node.size.width, h = node.size.height
        guard w > 0, h > 0 else { return false }
        let px = Int((lp.x + w / 2) / w * CGFloat(mask.width))
        let py = Int((1 - (lp.y + h / 2) / h) * CGFloat(mask.height))  // 이미지 y는 위가 0
        guard let a = mask.alpha(px, py) else { return false }
        return a >= alphaThreshold
    }

    /// 그 지점에서 '아직 안 깨진' 돌 중 맨 위(z 최고). 알파로 실제 그림 위만 인정.
    private func topLiveRockIndex(at p: CGPoint) -> Int? {
        guard let m = manager else { return nil }
        var best: Int?
        for i in pieces.indices where !m.pieces[i].isCleared {
            guard isOpaque(pieces[i], rockMasks[i], at: p) else { continue }
            if best == nil || pieces[i].zPosition > pieces[best!].zPosition { best = i }
        }
        return best
    }

    /// 그 지점에 '노출된 관'이 있는지(관 그림 픽셀 위 + 위를 덮은 산 돌이 없음).
    private func coffinExposed(at p: CGPoint) -> Bool {
        guard let node = coffinNode else { return false }
        return isOpaque(node, coffinMask, at: p)
    }

    // MARK: - 입력

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)

        if editMode {
            dragging = pieces.filter { $0.frame.contains(p) }.max { $0.zPosition < $1.zPosition }
            if let d = dragging { dragOffset = CGSize(width: p.x - d.position.x, height: p.y - d.position.y) }
            return
        }

        activeTouch = p
        if manager?.tool == .chisel { interact(at: p, dt: 0) }  // 끌은 누른 순간 1회
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        if editMode {
            guard let d = dragging else { return }
            d.position = CGPoint(x: p.x - dragOffset.width, y: p.y - dragOffset.height)
        } else {
            activeTouch = p
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch() }
    private func endTouch() { dragging = nil; activeTouch = nil }

    /// 한 지점에 도구를 적용: 산 돌이 있으면 깎고, 없고 관이 노출돼 있으면 실패.
    private func interact(at p: CGPoint, dt: TimeInterval) {
        guard let m = manager else { return }
        if let i = topLiveRockIndex(at: p) {
            switch m.tool {
            case .drill:  m.drill(pieceID: i, pressure: pressureProvider(), dt: dt)
            case .chisel: m.chisel(pieceID: i)
            }
        } else if coffinExposed(at: p) {
            m.touchCoffin()
        }
    }

    // MARK: - 매 프레임: 드릴 연속 처리 + 그림 갱신

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : currentTime - lastUpdate
        lastUpdate = currentTime

        if !editMode, manager?.tool == .drill, let p = activeTouch {
            interact(at: p, dt: dt)            // 드릴은 누르는 동안 매 프레임
        }
        refreshVisuals()
    }

    private func refreshVisuals() {
        guard let m = manager else { return }
        for piece in m.pieces where piece.id < pieces.count {
            let node = pieces[piece.id]
            if piece.isCleared {
                breakAway(id: piece.id, node: node)
            } else {
                node.color = .black
                node.colorBlendFactor = CGFloat((1 - piece.hp) * 0.6)   // 닳을수록 어둡게
            }
        }
    }

    /// 조각이 0이 됨: 톡 사라져 뒤의 관이 드러난다. (실패 판정은 관 픽셀로 별도 처리)
    private func breakAway(id: Int, node: SKSpriteNode) {
        guard !clearedShown.contains(id) else { return }
        clearedShown.insert(id)
        node.run(.sequence([
            .group([.fadeAlpha(to: 0, duration: 0.18), .scale(to: 0.7, duration: 0.18)]),
            .removeFromParent()
        ]))
    }

    /// 실패 연출: 화면 붉게 번쩍.
    func flashFail() {
        let flash = SKSpriteNode(color: .red, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 1000
        flash.alpha = 0
        addChild(flash)
        flash.run(.sequence([.fadeAlpha(to: 0.6, duration: 0.08),
                             .fadeAlpha(to: 0, duration: 0.25),
                             .removeFromParent()]))
    }

    // MARK: - 좌표 출력(배치 모드)

    func dumpPositions() {
        let lines = pieces
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
            .map { String(format: "    CGPoint(x: %.1f, y: %.1f), // %@",
                          $0.position.x, $0.position.y, $0.name ?? "") }
            .joined(separator: "\n")
        print("""

        // ▼▼▼ Stage1Scene.bakedLayout 에 붙여넣기 (designSize \(Int(Self.designSize.width))x\(Int(Self.designSize.height)))
        static let bakedLayout: [CGPoint]? = [
        \(lines)
        ]
        // ▲▲▲

        """)
    }

    private static func placeholderColor(_ id: Int) -> SKColor {
        let hues: [CGFloat] = [0.02, 0.08, 0.12, 0.55, 0.60, 0.75,
                               0.00, 0.33, 0.45, 0.85, 0.15, 0.50]
        return SKColor(hue: hues[id % hues.count], saturation: 0.5, brightness: 0.8, alpha: 1)
    }
}

// MARK: - 알파 마스크 (이미지의 픽셀 투명도 조회)

/// PNG의 알파값을 미리 뽑아 보관 → 터치 지점이 '실제 그림' 위인지 빠르게 판정.
struct AlphaMask {
    let width: Int
    let height: Int
    private let data: [UInt8]    // 픽셀별 알파(0~255). row 0 = 이미지 위쪽.

    init?(_ image: UIImage) {
        guard let cg = image.cgImage else { return nil }
        let w = cg.width, h = cg.height
        guard w > 0, h > 0 else { return nil }
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(data: &rgba, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: space, bitmapInfo: info) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var a = [UInt8](repeating: 0, count: w * h)
        for i in 0..<(w * h) { a[i] = rgba[i * 4 + 3] }   // 알파 채널만 추림
        self.width = w; self.height = h; self.data = a
    }

    func alpha(_ x: Int, _ y: Int) -> UInt8? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        return data[y * width + x]
    }
}
