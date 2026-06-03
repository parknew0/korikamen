//
//  Stage1Scene.swift
//  C3_Korikamen
//
//  Created by Park on 6/3/26.
//  Stage1(관 돌 부수기) SpriteKit 씬.
//
//  두 가지 모드:
//   - 플레이 모드(기본): 조각을 터치/펜슬로 깬다. 드릴=꾹 연속, 끌=툭 단발.
//     조각이 0이 되면 그 칸은 '관 노출' 상태가 되고, 거기 또 대면 실패.
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
    /// 관 위치 미세 조정(돌무더기 중심 기준). 그림이 안 맞으면 이 값만 바꾼다.
    static let coffinOffset = CGVector(dx: 0, dy: 0)
    /// 관 크기 조정(1.0 = 원본).
    static let coffinScale: CGFloat = 1.0

    // MARK: - 외부 연결(뷰에서 주입)

    /// 판정 두뇌. 씬은 이 매니저에 깨기 요청을 보내고, hp를 읽어 그림을 갱신한다.
    weak var manager: Stage1GameManager?
    /// 펜슬/Mock에서 오는 세기(0~1). 드릴 속도에 쓰인다.
    var pressureProvider: () -> Double = { 0 }
    /// true면 배치 모드(드래그). false면 플레이 모드(깨기). 기본 플레이.
    var editMode = false

    // MARK: - 내부 상태

    private var pieces: [SKSpriteNode] = []
    private var clearedShown = Set<Int>()      // 관 노출 연출을 이미 보여준 조각
    private var hasCoffin = false              // 관 그림이 깔렸는지(없으면 금빛 패치로 대체)
    private var activePieceID: Int?            // 드릴로 누르고 있는 조각
    private var lastUpdate: TimeInterval = 0

    // 배치 모드 드래그
    private var dragging: SKSpriteNode?
    private var dragOffset: CGSize = .zero

    private let coffinColor = SKColor(hue: 0.12, saturation: 0.7, brightness: 0.95, alpha: 1) // 금빛 관

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

    /// 돌무더기 뒤(zPosition -1)에 관 그림을 깐다. 처음엔 돌에 가려 안 보이다가, 돌이 깨지면 비친다.
    private func buildCoffin() {
        guard let img = UIImage(named: Self.coffinName) else { return }  // png 없으면 조용히 패스
        let node = SKSpriteNode(texture: SKTexture(image: img))
        node.name = "coffin"
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = -1
        node.setScale(Self.coffinScale)
        node.position = pileCenter(extra: Self.coffinOffset)
        addChild(node)
        hasCoffin = true
    }

    /// 돌무더기의 대략적 중심(+추가 오프셋). 관 위치 기준점.
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
            let node = makeNode(id: id, name: name)
            node.name = name
            node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            node.zPosition = CGFloat(id)                 // id 클수록 위 → 터치 우선권
            node.position = startPosition(id)
            addChild(node)
            pieces.append(node)
        }
    }

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

    /// 터치 지점을 덮는 조각 중 맨 위(z 최고). (조각이 타이트하게 잘려 있어 사각형 판정으로 충분)
    private func topPieceID(at p: CGPoint) -> Int? {
        pieces.enumerated()
            .filter { $0.element.frame.contains(p) }
            .max { $0.element.zPosition < $1.element.zPosition }?
            .offset
    }

    // MARK: - 입력

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)

        if editMode {
            dragging = pieces.filter { $0.frame.contains(p) }.max { $0.zPosition < $1.zPosition }
            if let d = dragging {
                dragOffset = CGSize(width: p.x - d.position.x, height: p.y - d.position.y)
            }
            return
        }

        // 플레이 모드
        guard let id = topPieceID(at: p) else { return }
        switch manager?.tool ?? .drill {
        case .drill:  activePieceID = id           // 누르는 동안 update에서 연속 처리
        case .chisel: manager?.chisel(pieceID: id) // 한 번 탕!
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        if editMode {
            guard let d = dragging else { return }
            d.position = CGPoint(x: p.x - dragOffset.width, y: p.y - dragOffset.height)
        } else if manager?.tool == .drill {
            activePieceID = topPieceID(at: p)       // 드릴을 끌고 다니면 닿는 조각 갱신
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragging = nil
        activePieceID = nil
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragging = nil
        activePieceID = nil
    }

    // MARK: - 매 프레임: 드릴 연속 처리 + 그림 갱신

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : currentTime - lastUpdate
        lastUpdate = currentTime

        if !editMode, let id = activePieceID, manager?.tool == .drill {
            manager?.drill(pieceID: id, pressure: pressureProvider(), dt: dt)
        }
        refreshVisuals()
    }

    /// 매니저의 hp 상태를 조각 그림에 반영.
    private func refreshVisuals() {
        guard let m = manager else { return }
        for piece in m.pieces where piece.id < pieces.count {
            let node = pieces[piece.id]
            if piece.isCleared {
                revealCoffin(id: piece.id, node: node)
            } else {
                // hp 닳을수록 어둡게(약해지는 느낌)
                node.color = .black
                node.colorBlendFactor = CGFloat((1 - piece.hp) * 0.6)
            }
        }
    }

    /// 조각이 0이 된 칸: 톡 깨지고 뒤의 관이 드러난다. 노드는 남겨 터치 판정 유지(닿으면 실패).
    private func revealCoffin(id: Int, node: SKSpriteNode) {
        guard !clearedShown.contains(id) else { return }
        clearedShown.insert(id)

        if hasCoffin {
            // 돌만 사라지고 뒤의 관 그림이 비친다. 투명(alpha 0)이라도 frame은 남아 터치 판정 유지.
            node.run(.fadeAlpha(to: 0, duration: 0.2))
        } else {
            // 관 png가 아직 없으면 금빛 패치로 대체(위치/판정은 동일).
            node.run(.sequence([
                .group([.fadeAlpha(to: 0, duration: 0.15), .scale(to: 0.6, duration: 0.15)]),
                .run { [coffinColor] in
                    node.texture = nil
                    node.color = coffinColor
                    node.colorBlendFactor = 1
                    node.setScale(1)
                },
                .fadeAlpha(to: 0.5, duration: 0.15)
            ]))
        }
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
