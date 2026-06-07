//
//  PencilState.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//
//  팀 공통 계약(Contract). 변경 시 팀 합의 필요.
//  게임 로직이 읽는 "번역된" 애플펜슬 입력의 한 순간 스냅샷.
//  raw UIKit 값(altitudeAngle, rollAngle, UIPencilInteraction 등)은
//  Feeder(RealPencilFeeder)가 이 형태로 변환해 채운다.
//  세부 계약: docs/contracts/pencil-input.md
//

import CoreGraphics

/// 애플펜슬 스퀴즈 단계.
/// Pencil Pro 스퀴즈는 연속 세기값이 아니라 단계 제스처라 phase만 둔다.
enum SqueezePhase {
    case none       // 스퀴즈 안 함
    case began      // 막 쥐기 시작
    case changed    // 쥐고 있는 중(유지)
    case ended      // 손 뗌(해당 프레임 1회)
}

enum PencilAngle {            // Barrel Roll 각도 정규화
    static func normalizedDegrees(_ value: Double) -> Double {
        let degrees = value.truncatingRemainder(dividingBy: 360)
        return degrees >= 0 ? degrees : degrees + 360       // 음수 각도 양수로 변환
    }
}

/// 한 순간의 펜슬 상태. 게임 로직은 raw API가 아니라 이 값만 읽는다.
/// (location/isTouching은 "펜슬" 접촉 기준 — Feeder가 손가락 터치는 걸러낸다.)
struct PencilState {

    // MARK: - 위치 / 접촉
    /// 접촉·호버 지점. 활성 스테이지 인터랙션 뷰의 로컬 좌표(pt). 없으면 nil.
    var location: CGPoint? = nil
    /// 펜이 화면(캔버스)에 닿아있나.            [Stage2 캔버스, Stage3-S1 드래그]
    var isTouching: Bool = false
    /// 화면 위에 떠서 호버 중인가.               [Stage1 조준]
    var isHovering: Bool = false

    // MARK: - 기울기 / 회전
    /// 기울기 0(수직)...90(수평) = 90 - altitude. [Stage2]
    /// ※ raw 값이다. 유효구간(예: 0~60) 적용은 스테이지의 게임 규칙.
    var tiltDegrees: Double = 0
    /// 배럴롤(rollAngle) 0...360.                [Stage2]
    var barrelRollDegrees: Double = 0

    // MARK: - 더블 탭 / 스퀴즈 (Pencil Pro)
    /// 더블 탭 카운트
    var doubleTapCount: Int = 0
    /// 스퀴즈 단계.                              [Stage3-S2]
    var squeezePhase: SqueezePhase = .none

    // MARK: - 편의 헬퍼
    /// 스퀴즈를 "쥐고 있는 중"인지. (began/changed 동안 true)
    var isSqueezing: Bool { squeezePhase == .began || squeezePhase == .changed }

}
