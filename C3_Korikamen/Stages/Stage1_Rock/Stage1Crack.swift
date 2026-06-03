//
//  Stage1Crack.swift
//  C3_Korikamen
//
//  Created by Park on 6/3/26.
//  돌 균열을 '이미지 없이' 절차적으로 생성/렌더하는 알고리즘.
//
//  아이디어:
//   - 조각 중심 근처에서 바깥으로 뻗는 지글지글한 선(가지)들을 미리 만든다(조각 id로 고정 시드).
//   - 각 가지에는 '나타나기 시작하는 손상도(startDamage)'가 있어, 손상이 커질수록 가지가 하나씩 등장.
//   - 등장한 가지는 손상에 따라 길이가 점점 자란다 → "점점 갈라지는" 느낌.
//   - 실제 그림은 SKCropNode로 돌 텍스처에 클리핑되어 돌 모양 밖으로 새지 않는다(씬에서 처리).
//

import SpriteKit

/// 균열 한 가닥(지글지글한 점들의 연결선) + 언제부터 나타날지.
struct Crack {
    let points: [CGPoint]   // 조각 로컬 좌표(중심 0,0 기준)
    let startDamage: Double // 0~1, 이 손상도부터 등장
}

enum CrackPattern {

    /// 조각 크기에 맞는 균열 패턴 생성. seed가 같으면 항상 같은 모양(조각별 고정).
    static func generate(seed: UInt64, width: CGFloat, height: CGFloat) -> [Crack] {
        var rng = SeededRNG(seed)
        let reach = max(width, height) * 0.8
        let origin = CGPoint(x: CGFloat.random(in: -width * 0.12...width * 0.12, using: &rng),
                             y: CGFloat.random(in: -height * 0.12...height * 0.12, using: &rng))

        var cracks: [Crack] = []
        let mainCount = 3
        let starts = [0.0, 0.12, 0.26]                 // 메인 균열이 차례로 등장
        let step = (2 * Double.pi) / Double(mainCount)

        for i in 0..<mainCount {
            let angle = Double(i) * step + Double.random(in: -0.5...0.5, using: &rng)
            let main = walk(from: origin, angle: angle, length: reach,
                            steps: 9, jitter: 0.45, &rng)
            cracks.append(Crack(points: main, startDamage: starts[i]))

            // 메인 중간 지점에서 곁가지 하나(조금 더 손상돼야 등장)
            if main.count > 4 {
                let mid = main[main.count / 2]
                let dir: Double = Bool.random(using: &rng) ? 1 : -1
                let subAngle = angle + dir * Double.random(in: 0.6...1.1, using: &rng)
                let sub = walk(from: mid, angle: subAngle, length: reach * 0.5,
                               steps: 5, jitter: 0.5, &rng)
                cracks.append(Crack(points: sub, startDamage: min(0.85, starts[i] + 0.3)))
            }
        }
        return cracks
    }

    /// 손상도(0~1)에 맞춰 현재 보여줄 균열 경로를 만든다.
    static func path(_ cracks: [Crack], damage: Double) -> CGPath {
        let path = CGMutablePath()
        for c in cracks where damage >= c.startDamage {
            let grow = min(1.0, (damage - c.startDamage) / 0.45)   // 0.45 손상 동안 끝까지 자람
            appendPolyline(path, c.points, fraction: CGFloat(grow))
        }
        return path
    }

    // MARK: - 내부

    /// 한 점에서 angle 방향으로 지글지글 걸어가며 점들을 만든다(가지 하나).
    private static func walk(from: CGPoint, angle: Double, length: CGFloat,
                             steps: Int, jitter: Double, _ rng: inout SeededRNG) -> [CGPoint] {
        var pts = [from]
        var p = from
        var a = angle
        let seg = length / CGFloat(steps)
        for _ in 0..<steps {
            a += Double.random(in: -jitter...jitter, using: &rng)
            p = CGPoint(x: p.x + CGFloat(cos(a)) * seg,
                        y: p.y + CGFloat(sin(a)) * seg)
            pts.append(p)
        }
        return pts
    }

    /// 폴리라인을 전체 길이의 fraction(0~1)만큼만 path에 그린다(자라나는 효과).
    private static func appendPolyline(_ path: CGMutablePath, _ points: [CGPoint], fraction: CGFloat) {
        guard points.count >= 2, fraction > 0 else { return }
        var segLens: [CGFloat] = []
        var total: CGFloat = 0
        for i in 1..<points.count {
            let d = hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y)
            segLens.append(d)
            total += d
        }
        let target = total * fraction
        path.move(to: points[0])
        var acc: CGFloat = 0
        for i in 1..<points.count {
            let len = segLens[i - 1]
            if acc + len <= target {
                path.addLine(to: points[i])
                acc += len
            } else {
                let remain = target - acc
                let t = len > 0 ? remain / len : 0
                let x = points[i - 1].x + (points[i].x - points[i - 1].x) * t
                let y = points[i - 1].y + (points[i].y - points[i - 1].y) * t
                path.addLine(to: CGPoint(x: x, y: y))
                break
            }
        }
    }
}

/// 결정적 난수(xorshift64). 같은 seed → 같은 수열 → 조각마다 균열 모양 고정.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(_ seed: UInt64) { state = seed != 0 ? seed : 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
