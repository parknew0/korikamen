//
//  Stage1Scene.swift
//  C3_Korikamen
//
//  Created by Park on 6/3/26.
//  Stage1(관 돌 부수기) SpriteKit 씬 — '조율자(coordinator)'.
//
//  씬은 노드 트리를 소유하고, 책임별 협력 객체에 위임만 한다(합성):
//   - Stage1Layout       : 배치/좌표 계산
//   - Stage1HitTester    : 알파 기반 판정(어느 돌? 노출된 관?)
//   - Stage1Effects      : 파편 + 흔들림 연출
//   - Stage1CrackOverlay : 균열 렌더링
//   - Stage1Scene+Debug  : 터치맵/히트박스/배치모드/dump (#if DEBUG)
//
//  입력 분담: 위치는 씬의 터치, 세기(pressure)는 PencilInput에서 주입(pressureProvider).
//

import SpriteKit

final class Stage1Scene: SKScene {

    /// 돌무더기 "뒤"에 깔리는 관 이미지. Assets에 이 이름의 png를 넣으면 자동으로 깔린다.
    static let coffinName = "coffin"

    /// 알파 판정 문턱(0~255). 이 값 이상이면 '실제 그림이 있는' 픽셀로 본다(돌용).
    private let alphaThreshold: UInt8 = 10
    /// 관 전용(더 높음) — 관 위험영역을 안쪽으로 줄여 가장자리에 안전 여유를 준다. 키울수록 더 관대.
    private let coffinAlphaThreshold: UInt8 = 160

    // MARK: - 외부 연결(뷰에서 주입)

    weak var manager: Stage1GameManager?
    var pressureProvider: () -> Double = { 0 }
    var editMode = false {
        didSet {
            activeTouch = nil
            #if DEBUG
            dragging = nil
            #endif
        }
    }
    /// 디버그: 히트박스/터치점/선택조각을 화면에 그린다.
    var showHitboxes = false
    /// 디버그: 실제 판정 결과를 색으로 칠한 '터치맵'(초록=돌 깎임, 빨강=관 닿아 실패).
    var showTouchMap = false {
        didSet {
            #if DEBUG
            showTouchMap ? buildTouchMap() : removeTouchMap()
            #endif
        }
    }

    // 실시간 조절용(조정모드 슬라이더가 씀). 바뀌면 즉시 재배치.
    var pilePosition = Stage1Layout.pilePosition   { didSet { layoutPile() } }
    var pileScale    = Stage1Layout.pileScale      { didSet { layoutPile() } }
    var coffinPosition = Stage1Layout.coffinPosition { didSet { layoutCoffin() } }
    var coffinScale    = Stage1Layout.coffinScale    { didSet { layoutCoffin() } }

    // MARK: - 노드/협력 객체

    private(set) var pieces: [SKSpriteNode] = []
    private var rockMasks: [Int: AlphaMask] = [:]   // 조각별 알파 마스크(에셋 있을 때)
    var coffinNode: SKSpriteNode?
    private var coffinMask: AlphaMask?
    private var debrisLayer: SKNode?                // 파편 전용 레이어(돌보다 항상 위, z 100)
    private var centers: [CGPoint] = []             // 조각의 '원래 중심'(흔들림 무시 기준)

    private let crackOverlay = Stage1CrackOverlay()
    private var effects: Stage1Effects?
    private(set) var hitTester: Stage1HitTester?

    // MARK: - 게임 진행 상태

    private var clearedShown = Set<Int>()
    var activeTouch: CGPoint?                       // 현재 누르고 있는 지점(플레이 모드)
    private var lastUpdate: TimeInterval = 0

    // MARK: - 디버그 상태 (Stage1Scene+Debug 가 사용)
    #if DEBUG
    var hitboxLayer: SKNode?
    var touchMapNode: SKSpriteNode?
    var lastPicked: Int?                            // 직전 터치에서 선택된 돌
    var lastCoffinHit = false                       // 직전 터치가 노출된 관이었는지
    var dragging: SKSpriteNode?                     // 배치 모드 드래그 대상
    var dragOffset: CGSize = .zero
    #endif

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .aspectFit
        backgroundColor = SKColor(white: 0.12, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        guard pieces.isEmpty else { return }   // 재진입 시 중복 생성 방지
        let layer = SKNode()                   // 파편 전용 레이어(돌 위)
        layer.zPosition = 100
        addChild(layer)
        debrisLayer = layer
        buildCoffin()                          // 먼저 관(뒤)
        buildPieces()                          // 그 위에 돌
        effects = Stage1Effects(view: view, debrisLayer: layer, pieceNodes: pieces, centers: centers)
        hitTester = Stage1HitTester(
            pieceNodes: pieces, rockMasks: rockMasks,
            coffinNode: coffinNode, coffinMask: coffinMask, centers: centers,
            alphaThreshold: alphaThreshold, coffinAlphaThreshold: coffinAlphaThreshold,
            isCleared: { [weak self] i in self?.manager?.pieces[i].isCleared ?? true })
    }

    // MARK: - 빌드 & 배치

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

    private func buildPieces() {
        for id in 0..<Stage1Layout.pieceCount {
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
                node = SKSpriteNode(color: Stage1Layout.placeholderColor(id), size: size)
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
            crackOverlay.attach(to: node, id: id, maskSprite: maskSprite)
        }
        layoutPile()    // 위치·크기 일괄 적용
    }

    /// 조각들을 Stage1Layout이 계산한 좌표로 재배치 + 협력 객체에 '원래 중심'을 동기화.
    private func layoutPile() {
        guard !pieces.isEmpty else { return }
        let positions = Stage1Layout.piecePositions(pilePosition: pilePosition, pileScale: pileScale)
        centers = positions
        for i in pieces.indices where i < positions.count {
            pieces[i].setScale(pileScale)
            pieces[i].position = positions[i]
        }
        hitTester?.updateCenters(positions)   // 흔들림 무시한 판정 기준
        effects?.updateCenters(positions)     // 흔들림 복귀 기준
    }

    private func layoutCoffin() {
        coffinNode?.setScale(coffinScale)
        coffinNode?.position = coffinPosition
    }

    private func rockColor(_ id: Int) -> SKColor {
        hitTester?.rockColor(id) ?? Stage1Layout.placeholderColor(id)
    }

    // MARK: - 입력

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)

        if editMode {
            #if DEBUG
            debugBeginDrag(at: p)
            #endif
            return
        }

        activeTouch = p
        #if DEBUG
        debugUpdatePick(at: p)                                   // 무엇이 잡혔는지 기록
        #endif
        if manager?.tool == .chisel { interact(at: p, dt: 0) }  // 끌은 누른 순간 1회
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        if editMode {
            #if DEBUG
            debugMoveDrag(at: p)
            #endif
        } else {
            activeTouch = p
            #if DEBUG
            debugUpdatePick(at: p)
            #endif
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endTouch() }
    private func endTouch() {
        activeTouch = nil
        effects?.stopDrillShake(); effects?.stopDrillDebris()   // 손 떼면 드릴 진동/파편 정지
        #if DEBUG
        debugEndTouch()
        #endif
    }

    /// 한 지점에 도구를 적용: 산 돌이 있으면 깎고, 없고 관이 노출돼 있으면 실패.
    private func interact(at p: CGPoint, dt: TimeInterval) {
        guard let m = manager, let hit = hitTester else { return }
        if let i = hit.topLiveRockIndex(at: p) {
            switch m.tool {
            case .drill:
                m.drill(pieceID: i, pressure: pressureProvider(), dt: dt)
                effects?.startDrillShake(id: i)                 // 연속 진동
                effects?.drillDebris(at: p, color: rockColor(i))// 연속 파편
            case .chisel:
                m.chisel(pieceID: i)
                effects?.shakeOnce(id: i)                       // 타격당 1번 흔들림
                effects?.burstDebris(at: p, color: rockColor(i))// 타격당 파편 버스트
            }
        } else if hit.coffinDanger(at: p) {
            m.touchCoffin()
            effects?.stopDrillShake(); effects?.stopDrillDebris()
        } else if m.tool == .drill {                            // 빈 공간/안전한 틈이면 드릴 효과 멈춤
            effects?.stopDrillShake(); effects?.stopDrillDebris()
        }
    }

    // MARK: - 매 프레임: 드릴 연속 처리 + 그림 갱신

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : currentTime - lastUpdate
        lastUpdate = currentTime

        if !editMode, manager?.tool == .drill, let p = activeTouch {
            #if DEBUG
            debugUpdatePick(at: p)             // 드릴 끌고 다닐 때 선택 갱신
            #endif
            interact(at: p, dt: dt)            // 드릴은 누르는 동안 매 프레임
        }
        refreshVisuals()
        #if DEBUG
        renderHitboxes()
        #endif
    }

    private func refreshVisuals() {
        guard let m = manager else { return }
        for piece in m.pieces where piece.id < pieces.count {
            let node = pieces[piece.id]
            if piece.isCleared {
                breakAway(id: piece.id, node: node)
            } else {
                crackOverlay.update(id: piece.id, damage: 1 - piece.hp)   // 닳을수록 갈라짐
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
        #if DEBUG
        if showTouchMap { buildTouchMap() }   // 깨진 조각의 초록 제거 → 아래 영역이 드러나게 갱신
        #endif
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
}
