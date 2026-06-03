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

    /// 무더기 "전체"의 화면상 중심 위치(조정모드로 맞춘 값을 여기 박는다).
    static let pilePosition = CGPoint(x: 502.7, y: 420.0)
    /// 무더기 "전체" 크기 배율(1.0 = 원본). 그룹 통째 스케일이라 조각 간 상대 간격은 유지된다.
    static let pileScale: CGFloat = 1.0

    /// 돌무더기 "뒤"에 깔리는 관 이미지. Assets에 이 이름의 png를 넣으면 자동으로 깔린다.
    static let coffinName = "coffin"
    /// 관의 화면상 중심 위치.
    static let coffinPosition = CGPoint(x: 502.7, y: 420.0)
    /// 관 크기 배율(1.0 = 원본).
    static let coffinScale: CGFloat = 1.0

    /// 알파 판정 문턱(0~255). 이 값 이상이면 '실제 그림이 있는' 픽셀로 본다.
    private let alphaThreshold: UInt8 = 20

    // MARK: - 외부 연결(뷰에서 주입)

    weak var manager: Stage1GameManager?
    var pressureProvider: () -> Double = { 0 }
    var editMode = false {
        didSet { activeTouch = nil; dragging = nil }
    }
    /// 디버그: 히트박스/터치점/선택조각을 화면에 그린다.
    var showHitboxes = false

    // 실시간 조절용(조정모드 슬라이더가 씀). 바뀌면 즉시 재배치.
    var pilePosition = Stage1Scene.pilePosition   { didSet { layoutPile() } }
    var pileScale    = Stage1Scene.pileScale      { didSet { layoutPile() } }
    var coffinPosition = Stage1Scene.coffinPosition { didSet { layoutCoffin() } }
    var coffinScale    = Stage1Scene.coffinScale    { didSet { layoutCoffin() } }

    // MARK: - 내부 상태

    private var pieces: [SKSpriteNode] = []
    private var rockMasks: [Int: AlphaMask] = [:]   // 조각별 알파 마스크(에셋 있을 때)
    private var coffinNode: SKSpriteNode?
    private var coffinMask: AlphaMask?

    // 균열(절차적) 상태
    private var crackDark: [Int: SKShapeNode] = [:]     // 어두운 균열선
    private var crackGlow: [Int: SKShapeNode] = [:]     // 밝은 하이라이트(어떤 돌색에도 보이게)
    private var crackPatterns: [Int: [Crack]] = [:]
    private var crackBucket: [Int: Int] = [:]           // 손상 단계 캐시(매 프레임 재생성 방지)

    private var clearedShown = Set<Int>()
    private var activeTouch: CGPoint?               // 현재 누르고 있는 지점(플레이 모드)
    private var lastUpdate: TimeInterval = 0

    // 타격 효과(흔들림 + 파편)
    private var basePositions: [Int: CGPoint] = [:] // 흔들림 후 되돌릴 기준 위치
    private var chipTexture: SKTexture?             // 파편용 칩 텍스처(1회 생성 후 재사용)
    private var drillEmitter: SKEmitterNode?        // 드릴 연속 파편(있는 동안 birthRate만 토글)
    private var drillShakeID: Int?                  // 지금 드릴 진동 중인 조각
    private var debrisLayer: SKNode?                // 파편 전용 레이어(돌보다 항상 위, z 100)

    // 디버그 시각화 상태
    private var hitboxLayer: SKNode?
    private var lastPicked: Int?                    // 직전 터치에서 선택된 돌
    private var lastCoffinHit = false               // 직전 터치가 노출된 관이었는지

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
        chipTexture = makeChipTexture(in: view)
        let layer = SKNode()                   // 파편 전용 레이어(돌 위)
        layer.zPosition = 100
        addChild(layer)
        debrisLayer = layer
        buildCoffin()                          // 먼저 관(뒤)
        buildPieces()                          // 그 위에 돌
    }

    // MARK: - 타격 효과(파편/흔들림)

    /// 들쭉날쭉한 작은 돌칩 텍스처를 1회만 만들어 모든 파편이 공유(생성 비용 절감).
    private func makeChipTexture(in view: SKView) -> SKTexture? {
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
    private func burstDebris(at p: CGPoint, color: SKColor) {
        let e = makeDebrisEmitter(color: color)
        e.position = p
        e.numParticlesToEmit = 12
        e.particleBirthRate = 600
        (debrisLayer ?? self).addChild(e)
        // 다 뿜고 수명 지나면 정리
        e.run(.sequence([.wait(forDuration: 1.0), .removeFromParent()]))
    }

    /// 드릴 연속 파편: 이미터 1개를 켜둔 채 위치/색만 갱신, 멈추면 birthRate 0.
    private func drillDebris(at p: CGPoint, color: SKColor) {
        if drillEmitter == nil {
            let e = makeDebrisEmitter(color: color)
            e.numParticlesToEmit = 0            // 무한(연속)
            (debrisLayer ?? self).addChild(e)
            drillEmitter = e
        }
        drillEmitter?.position = p
        drillEmitter?.particleColor = color
        drillEmitter?.particleBirthRate = 70
    }

    private func stopDrillDebris() { drillEmitter?.particleBirthRate = 0 }

    private func rockColor(_ id: Int) -> SKColor {
        rockMasks[id]?.color ?? Self.placeholderColor(id)
    }

    /// 끌: 한 번 툭 흔들고 제자리로(되돌아오는 시퀀스라 위치 안 틀어짐).
    private func shakeOnce(id: Int) {
        let n = pieces[id]
        let a: CGFloat = 3
        n.run(.sequence([
            .moveBy(x: a, y: -a * 0.5, duration: 0.03),
            .moveBy(x: -a * 2, y: a, duration: 0.05),
            .moveBy(x: a, y: -a * 0.5, duration: 0.03)
        ]), withKey: "shake")
    }

    /// 드릴: 해당 조각에 연속 진동(repeatForever). 다른 조각으로 옮기면 이전 건 멈춤.
    private func startDrillShake(id: Int) {
        guard drillShakeID != id else { return }
        stopDrillShake()
        drillShakeID = id
        let j: CGFloat = 1.8
        let cycle = SKAction.sequence([
            .moveBy(x: j, y: j * 0.6, duration: 0.02),
            .moveBy(x: -j * 2, y: -j * 1.2, duration: 0.04),
            .moveBy(x: j, y: j * 0.6, duration: 0.02)
        ])
        pieces[id].run(.repeatForever(cycle), withKey: "drillShake")
    }

    private func stopDrillShake() {
        if let id = drillShakeID {
            pieces[id].removeAction(forKey: "drillShake")
            pieces[id].position = basePositions[id] ?? pieces[id].position   // 잔여 오프셋 제거
        }
        drillShakeID = nil
    }

    // MARK: - 관(배경 레이어)

    private func buildCoffin() {
        guard let img = UIImage(named: Self.coffinName) else { return }  // png 없으면 패스
        let node = SKSpriteNode(texture: SKTexture(image: img))
        node.name = "coffin"
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = -1
        addChild(node)
        coffinNode = node
        coffinMask = AlphaMask(img)
        layoutCoffin()
    }

    /// bakedLayout의 평균(무더기 원래 중심). 그룹 스케일/이동의 기준점.
    private var layoutCentroid: CGPoint {
        guard let layout = Self.bakedLayout, !layout.isEmpty else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        let cx = layout.map { $0.x }.reduce(0, +) / CGFloat(layout.count)
        let cy = layout.map { $0.y }.reduce(0, +) / CGFloat(layout.count)
        return CGPoint(x: cx, y: cy)
    }

    /// 조각들을 (원래 상대 배치 × pileScale) + pilePosition 으로 재배치. 상대 간격은 유지된다.
    private func layoutPile() {
        guard !pieces.isEmpty, let layout = Self.bakedLayout else { return }
        let c = layoutCentroid
        for i in pieces.indices where i < layout.count {
            let rel = CGPoint(x: layout[i].x - c.x, y: layout[i].y - c.y)   // 중심 대비 상대 위치
            pieces[i].setScale(pileScale)
            let pos = CGPoint(x: pilePosition.x + rel.x * pileScale,
                              y: pilePosition.y + rel.y * pileScale)
            pieces[i].position = pos
            basePositions[i] = pos            // 흔들림 복귀 기준
        }
    }

    private func layoutCoffin() {
        coffinNode?.setScale(coffinScale)
        coffinNode?.position = coffinPosition
    }

    // MARK: - 조각 생성

    private func buildPieces() {
        for id in 0..<Self.pieceCount {
            let name = String(format: "rock_%02d", id)
            let node: SKSpriteNode
            let maskSprite: SKSpriteNode    // 균열 클리핑용(돌 모양)
            if let img = UIImage(named: name) {
                let tex = SKTexture(image: img)
                node = SKSpriteNode(texture: tex)
                rockMasks[id] = AlphaMask(img)
                maskSprite = SKSpriteNode(texture: tex)
            } else {
                let size = CGSize(width: 110, height: 110)
                node = SKSpriteNode(color: Self.placeholderColor(id), size: size)
                let label = SKLabelNode(text: "\(id)")
                label.verticalAlignmentMode = .center
                label.fontSize = 36
                node.addChild(label)
                maskSprite = SKSpriteNode(color: .white, size: size)
            }
            node.name = name
            node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            node.zPosition = CGFloat(id)                 // id 클수록 위 → 터치 우선권
            addChild(node)
            pieces.append(node)
            attachCracks(to: node, id: id, mask: maskSprite)
        }
        layoutPile()    // 위치·크기 일괄 적용
    }

    /// 돌 모양에 클리핑되는 균열 오버레이(밝은 선 + 어두운 선)를 조각 위에 얹는다.
    private func attachCracks(to node: SKSpriteNode, id: Int, mask: SKSpriteNode) {
        mask.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        mask.position = .zero
        let crop = SKCropNode()
        crop.maskNode = mask              // 돌 그림이 있는 픽셀에서만 균열이 보임
        crop.zPosition = 1                // 돌 텍스처 위

        let glow = SKShapeNode()          // 밝은 하이라이트(아래)
        glow.strokeColor = SKColor(white: 1, alpha: 0.35)
        glow.lineWidth = 4
        glow.lineCap = .round
        glow.lineJoin = .round

        let dark = SKShapeNode()          // 어두운 균열(위)
        dark.strokeColor = SKColor(white: 0, alpha: 0.85)
        dark.lineWidth = 2
        dark.lineCap = .round
        dark.lineJoin = .round

        crop.addChild(glow)
        crop.addChild(dark)
        node.addChild(crop)

        crackGlow[id] = glow
        crackDark[id] = dark
        crackPatterns[id] = CrackPattern.generate(seed: UInt64(id + 1),
                                                   width: node.size.width,
                                                   height: node.size.height)
        crackBucket[id] = -1
    }

    /// 손상도에 맞춰 균열 경로/굵기 갱신(단계가 바뀔 때만 재생성).
    private func updateCracks(id: Int, damage: Double) {
        let bucket = Int(damage * 24)
        guard crackBucket[id] != bucket else { return }
        crackBucket[id] = bucket
        guard let pattern = crackPatterns[id] else { return }
        let path = CrackPattern.path(pattern, damage: damage)
        crackDark[id]?.path = path
        crackGlow[id]?.path = path
        crackDark[id]?.lineWidth = 1.5 + CGFloat(damage) * 2.0   // 손상 클수록 굵게
        crackGlow[id]?.lineWidth = 3.5 + CGFloat(damage) * 2.5
    }

    // MARK: - 알파 기반 판정

    /// 그 지점이 노드의 '실제 그림' 위인지(투명 모서리는 false). 마스크 없으면 사각형 전체 solid.
    /// 판정은 흔들림(shake) 전의 '원래 중심(center)' 기준 → 진동 중에도 선택이 안 흔들린다.
    private func isOpaque(_ node: SKSpriteNode, _ mask: AlphaMask?, center: CGPoint, at p: CGPoint) -> Bool {
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
        return a >= alphaThreshold
    }

    /// 그 지점에서 '아직 안 깨진' 돌 중 맨 위(z 최고). 알파로 실제 그림 위만 인정.
    private func topLiveRockIndex(at p: CGPoint) -> Int? {
        guard let m = manager else { return nil }
        var best: Int?
        for i in pieces.indices where !m.pieces[i].isCleared {
            let center = basePositions[i] ?? pieces[i].position       // 흔들림 무시한 원래 위치
            guard isOpaque(pieces[i], rockMasks[i], center: center, at: p) else { continue }
            if best == nil || pieces[i].zPosition > pieces[best!].zPosition { best = i }
        }
        return best
    }

    /// 그 지점에 '노출된 관'이 있는지(관 그림 픽셀 위 + 위를 덮은 산 돌이 없음).
    private func coffinExposed(at p: CGPoint) -> Bool {
        guard let node = coffinNode else { return false }
        return isOpaque(node, coffinMask, center: node.position, at: p)
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
        updatePick(at: p)                                       // 디버그: 무엇이 잡혔는지 기록
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
            updatePick(at: p)
        }
    }

    /// 디버그: 현재 지점에서 뭐가 잡히는지(돌 index 또는 노출된 관) 계산해 기록 + 콘솔 출력.
    private func updatePick(at p: CGPoint) {
        let picked = topLiveRockIndex(at: p)
        lastPicked = picked
        lastCoffinHit = (picked == nil) && coffinExposed(at: p)
        if showHitboxes {
            if let i = picked { print("👉 터치 → 돌 rock_\(String(format: "%02d", i)) 선택") }
            else if lastCoffinHit { print("👉 터치 → 노출된 관(실패 지점)") }
            else { print("👉 터치 → 아무것도 없음(빈 공간)") }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch() }
    private func endTouch() {
        dragging = nil; activeTouch = nil; lastPicked = nil; lastCoffinHit = false
        stopDrillShake(); stopDrillDebris()        // 손 떼면 드릴 진동/파편 정지
    }

    /// 한 지점에 도구를 적용: 산 돌이 있으면 깎고, 없고 관이 노출돼 있으면 실패.
    private func interact(at p: CGPoint, dt: TimeInterval) {
        guard let m = manager else { return }
        if let i = topLiveRockIndex(at: p) {
            switch m.tool {
            case .drill:
                m.drill(pieceID: i, pressure: pressureProvider(), dt: dt)
                startDrillShake(id: i)                       // 연속 진동
                drillDebris(at: p, color: rockColor(i))      // 연속 파편
            case .chisel:
                m.chisel(pieceID: i)
                shakeOnce(id: i)                             // 타격당 1번 흔들림
                burstDebris(at: p, color: rockColor(i))      // 타격당 파편 버스트
            }
        } else if coffinExposed(at: p) {
            m.touchCoffin()
            stopDrillShake(); stopDrillDebris()
        } else if m.tool == .drill {                          // 빈 공간으로 빠지면 드릴 효과 멈춤
            stopDrillShake(); stopDrillDebris()
        }
    }

    // MARK: - 매 프레임: 드릴 연속 처리 + 그림 갱신

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : currentTime - lastUpdate
        lastUpdate = currentTime

        if !editMode, manager?.tool == .drill, let p = activeTouch {
            updatePick(at: p)                  // 드릴 끌고 다닐 때 선택 갱신(디버그)
            interact(at: p, dt: dt)            // 드릴은 누르는 동안 매 프레임
        }
        refreshVisuals()
        renderHitboxes()
    }

    /// 디버그 오버레이: 살아있는 돌 사각범위(선택=초록), 관 범위(노출 닿음=빨강), 터치점(노랑).
    private func renderHitboxes() {
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

    private func refreshVisuals() {
        guard let m = manager else { return }
        for piece in m.pieces where piece.id < pieces.count {
            let node = pieces[piece.id]
            if piece.isCleared {
                breakAway(id: piece.id, node: node)
            } else {
                updateCracks(id: piece.id, damage: 1 - piece.hp)        // 닳을수록 갈라짐
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

    /// 조정모드에서 맞춘 무더기/관 위치·배율을 Stage1Scene 상단 상수에 붙여넣을 형태로 출력.
    func dumpTransform() {
        print("""

        // ▼▼▼ Stage1Scene 상단 상수에 붙여넣기 (조정모드 결과)
        static let pilePosition = CGPoint(x: \(String(format: "%.1f", pilePosition.x)), y: \(String(format: "%.1f", pilePosition.y)))
        static let pileScale: CGFloat = \(String(format: "%.3f", pileScale))
        static let coffinPosition = CGPoint(x: \(String(format: "%.1f", coffinPosition.x)), y: \(String(format: "%.1f", coffinPosition.y)))
        static let coffinScale: CGFloat = \(String(format: "%.3f", coffinScale))
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
    let color: SKColor          // 불투명 픽셀들의 평균색(파편 색으로 사용 = '컬러 피커' 역할)
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
        var rSum = 0.0, gSum = 0.0, bSum = 0.0, count = 0.0
        for i in 0..<(w * h) {
            let alpha = rgba[i * 4 + 3]
            a[i] = alpha
            if alpha > 40 {                          // 불투명 픽셀만 평균에 반영
                // premultiplied → 원색 복원
                let af = Double(alpha) / 255.0
                rSum += Double(rgba[i * 4 + 0]) / af
                gSum += Double(rgba[i * 4 + 1]) / af
                bSum += Double(rgba[i * 4 + 2]) / af
                count += 1
            }
        }
        self.width = w; self.height = h; self.data = a
        if count > 0 {
            self.color = SKColor(red: CGFloat(min(255, rSum / count) / 255.0),
                                 green: CGFloat(min(255, gSum / count) / 255.0),
                                 blue: CGFloat(min(255, bSum / count) / 255.0),
                                 alpha: 1)
        } else {
            self.color = SKColor(white: 0.6, alpha: 1)   // 폴백(회색)
        }
    }

    func alpha(_ x: Int, _ y: Int) -> UInt8? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        return data[y * width + x]
    }
}
