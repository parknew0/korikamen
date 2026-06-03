//
//  Stage1GameManager.swift
//  C3_Korikamen
//
//  Created by Park on 6/3/26.
//  Stage1(관 돌 부수기) 판정 로직 전담.
//
//  순수 로직만 담는다(렌더링·화면 좌표 의존 X).
//  뷰가 "어느 조각(pieceID)"인지만 알려주면 매니저가 HP·관 손상·클리어를 판정.
//  → 시뮬레이터 + MockPencilFeeder(슬라이더)로 검증 가능.
//

import Foundation
import Combine

/// 도구 2종. 드릴(빠르지만 위험) / 끌(안전하지만 느림).
enum Stage1Tool {
    case drill   // Pressure 누르는 동안 연속 작동, 세게 누를수록 빠름
    case chisel  // Pressure 누를 때마다 1회 타격, 고정 감소
}

/// 바위를 분할한 한 조각. 독립적인 HP를 가진다.
struct RockPiece: Identifiable {
    let id: Int
    var hp: Double = 1.0                 // 1.0(멀쩡) → 0(소멸)

    /// 조각 소멸 여부. 소멸한 칸 = 아래 관(유물)이 드러난 위험 영역.
    var isCleared: Bool { hp <= 0 }

    /// HP 단계 → 균열 이미지 선택용. 0:멀쩡 1:금(66%) 2:심한금(33%) 3:소멸
    var crackStage: Int {
        switch hp {
        case let h where h > 0.66: return 0
        case let h where h > 0.33: return 1
        case let h where h > 0:    return 2
        default:                   return 3
        }
    }
}

final class Stage1GameManager: ObservableObject {

    // 보관할 값들
    @Published private(set) var pieces: [RockPiece]   // 돌 조각들(각자 HP)
    @Published var tool: Stage1Tool = .drill          // 현재 도구(버튼 탭으로 전환)
    @Published private(set) var didDamageCoffin = false // 실패 ① 트리거(관 손상)

    // 튜닝 상수 (추후 플레이 테스트로 조정) — 한곳에 모음
    private let drillRate: Double = 0.9    // 드릴: 초당 최대 감소량(pressure=1, dt=1 기준)
    private let chiselDamage: Double = 0.2 // 끌: 1회 타격당 고정 감소량

    /// 클리어: 모든 조각 HP 0.
    var isCleared: Bool { pieces.allSatisfy { $0.isCleared } }

    /// pieceCount 개로 바위를 분할해 시작. (에셋이 조각 12장이라 기본 12)
    init(pieceCount: Int = 12) {
        pieces = (0..<pieceCount).map { RockPiece(id: $0) }
    }

    // MARK: - 도구 전환

    func selectTool(_ t: Stage1Tool) { tool = t }

    // MARK: - 드릴 (연속) — 누르는 동안 매 tick 호출

    /// pieceID 조각에 pressure(0~1) 세기로 dt(초)만큼 드릴 적용.
    /// 이미 소멸한 칸(관 노출)이면 즉시 관 손상 → 실패 ①.
    func drill(pieceID: Int, pressure: Double, dt: Double) {
        guard pressure > 0, let i = index(of: pieceID) else { return }
        if hitsCoffin(at: i) { return }
        damage(at: i, amount: pressure * drillRate * dt)
    }

    // MARK: - 끌 (단발) — 타격마다 1회 호출

    /// pieceID 조각을 끌로 1회 타격. 고정 감소.
    /// 이미 소멸한 칸(관 노출)이면 즉시 관 손상 → 실패 ①.
    func chisel(pieceID: Int) {
        guard let i = index(of: pieceID) else { return }
        if hitsCoffin(at: i) { return }
        damage(at: i, amount: chiselDamage)
    }

    // MARK: - 내부 처리

    private func index(of pieceID: Int) -> Int? {
        pieces.firstIndex { $0.id == pieceID }
    }

    /// 소멸한 조각 자리(=관 노출 영역)에 도구가 닿았는가. 닿았으면 실패 플래그 set.
    private func hitsCoffin(at i: Int) -> Bool {
        if pieces[i].isCleared {
            didDamageCoffin = true
            return true
        }
        return false
    }

    private func damage(at i: Int, amount: Double) {
        pieces[i].hp = max(0, pieces[i].hp - amount)
    }
}
