//
//  Stage1Scene.swift
//  C3_Korikamen
//
//  Created by Park on 6/3/26.
//  Stage1(관 돌 부수기) SpriteKit 씬.
//
//  지금은 "배치 모드"가 핵심:
//   - 조각 12장(rock_00 ~ rock_11)을 화면에 흩뿌리고
//   - 손/펜슬로 끌어서 자연스럽게 겹쳐 배치한 뒤
//   - "좌표 출력"으로 위치를 콘솔에 찍는다 → bakedLayout에 박아 고정.
//  좌표가 확정되면 같은 씬이 그대로 플레이 씬이 된다(터치 판정은 다음 단계).
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
    /// (기본값은 무더기를 화면 세로 중앙쯤으로 끌어올린 것 — 보면서 마음대로 조절하세요.)
    static let clusterOffset = CGVector(dx: 0, dy: 67)

    private var pieces: [SKSpriteNode] = []

    // 드래그 상태(배치 모드)
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
        buildPieces()
    }

    // MARK: - 조각 생성

    private func buildPieces() {
        for id in 0..<Self.pieceCount {
            let name = String(format: "rock_%02d", id)
            let node = makeNode(id: id, name: name)
            node.name = name
            node.anchorPoint = CGPoint(x: 0.5, y: 0.5)   // position = 중심
            node.zPosition = CGFloat(id)                 // id 클수록 위 → 터치 우선권
            node.position = startPosition(id)
            addChild(node)
            pieces.append(node)
        }
    }

    /// 에셋이 있으면 그 이미지, 아직 없으면 번호 적힌 색 사각형(배치 도구는 미리 테스트 가능).
    private func makeNode(id: Int, name: String) -> SKSpriteNode {
        if let img = UIImage(named: name) {
            return SKSpriteNode(texture: SKTexture(image: img))
        }
        let node = SKSpriteNode(color: Self.placeholderColor(id),
                                size: CGSize(width: 110, height: 110))
        let label = SKLabelNode(text: "\(id)")
        label.verticalAlignmentMode = .center
        label.fontSize = 36
        node.addChild(label)
        return node
    }

    private func startPosition(_ id: Int) -> CGPoint {
        if let layout = Self.bakedLayout, id < layout.count {
            // 상대 위치 + 무더기 전체 이동(clusterOffset)
            return CGPoint(x: layout[id].x + Self.clusterOffset.dx,
                           y: layout[id].y + Self.clusterOffset.dy)
        }
        // 배치 모드: 4열 격자로 흩뿌려 전부 잡히게
        let cols = 4
        let rows = (Self.pieceCount + cols - 1) / cols
        let col = id % cols, row = id / cols
        let cellW = size.width  / CGFloat(cols + 1)
        let cellH = size.height / CGFloat(rows + 1)
        return CGPoint(x: cellW * CGFloat(col + 1),
                       y: size.height - cellH * CGFloat(row + 1))
    }

    // MARK: - 배치 모드 드래그

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        // 터치 지점을 포함하는 조각 중 맨 위(z 최고) 것을 집는다.
        dragging = pieces
            .filter { $0.frame.contains(p) }
            .max { $0.zPosition < $1.zPosition }
        if let d = dragging {
            dragOffset = CGSize(width: p.x - d.position.x, height: p.y - d.position.y)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, let d = dragging else { return }
        let p = t.location(in: self)
        d.position = CGPoint(x: p.x - dragOffset.width, y: p.y - dragOffset.height)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { dragging = nil }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { dragging = nil }

    // MARK: - 좌표 출력

    /// 현재 조각 위치를 Xcode 콘솔에 Swift 배열 형태로 찍는다. 그대로 bakedLayout에 붙여넣으면 됨.
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
