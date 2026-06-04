//
//  Stage1Layout.swift
//  C3_Korikamen
//
//  Stage1(관 돌 부수기)의 '배치/좌표' 정책만 담는 순수 계산 모듈.
//  - 조각 무더기의 baked 상대 배치 + 무더기 전체 위치/배율 → 각 조각의 화면 좌표 계산.
//  - 관/무더기의 기본 위치·배율 상수.
//  렌더링·노드·판정은 갖지 않는다(값 계산만). 씬이 결과를 노드에 적용한다.
//

import SpriteKit

enum Stage1Layout {

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
    /// (조정모드로 맞춘 값. 저장값이 없을 때의 기본 = Stage1Transform.fallback)
    static let pileScale: CGFloat = 0.737

    /// 관의 화면상 중심 위치.
    static let coffinPosition = CGPoint(x: 502.7, y: 420.0)
    /// 관 크기 배율(1.0 = 원본).
    static let coffinScale: CGFloat = 0.755

    /// 돌 터치 여유(화면 포인트). 돌 실루엣을 이만큼 바깥으로 넓혀 판정한다.
    /// 0 = 실루엣과 정확히 일치(기본). 누르기 빡빡하면 몇 포인트 올리면 가장자리가 관대해진다.
    /// (frame 기반 판정으로 축소 시 undersizing이 해소돼, 여유 없이도 돌과 맞는다.)
    static let rockTouchTolerance: CGFloat = 0

    /// bakedLayout의 평균(무더기 원래 중심). 그룹 스케일/이동의 기준점.
    static var centroid: CGPoint {
        guard let layout = bakedLayout, !layout.isEmpty else {
            return CGPoint(x: designSize.width / 2, y: designSize.height / 2)
        }
        let cx = layout.map { $0.x }.reduce(0, +) / CGFloat(layout.count)
        let cy = layout.map { $0.y }.reduce(0, +) / CGFloat(layout.count)
        return CGPoint(x: cx, y: cy)
    }

    /// 각 조각의 화면 좌표 = (원래 상대 배치 × pileScale) + pilePosition. 상대 간격은 유지된다.
    static func piecePositions(pilePosition: CGPoint, pileScale: CGFloat) -> [CGPoint] {
        guard let layout = bakedLayout else { return [] }
        let c = centroid
        return layout.map { p in
            let rel = CGPoint(x: p.x - c.x, y: p.y - c.y)   // 중심 대비 상대 위치
            return CGPoint(x: pilePosition.x + rel.x * pileScale,
                           y: pilePosition.y + rel.y * pileScale)
        }
    }

    /// 에셋이 없을 때 조각 식별용 임시 색.
    static func placeholderColor(_ id: Int) -> SKColor {
        let hues: [CGFloat] = [0.02, 0.08, 0.12, 0.55, 0.60, 0.75,
                               0.00, 0.33, 0.45, 0.85, 0.15, 0.50]
        return SKColor(hue: hues[id % hues.count], saturation: 0.5, brightness: 0.8, alpha: 1)
    }
}
