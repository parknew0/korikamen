//
//  Stage2LockGaugeView.swift
//  C3_Korikamen
//
//  Created by Yourim on 6/4/26.
//

import Combine
import CoreGraphics
import SwiftUI

private struct Stage2LockLevel {
    let tiltLower: Double
    let tiltUpper: Double
    let rollLower: Double
    let rollUpper: Double
}

struct LockGaugeView: View {
    @EnvironmentObject private var pencil: PencilInput      // 펜슬 입력
    
    @StateObject private var haptics = Haptics()    // 햅틱
    
    @State private var tiltRangeLower = 35.0        // 목표 Tilt 범위(Lower)
    @State private var tiltRangeUpper = 55.0        // 목표 Tilt 범위(Upper)
    @State private var rollRangeLower = 160.0       // 목표 Barrel Roll 범위(Lower)
    @State private var rollRangeUpper = 200.0       // 목표 Barrel Roll 범위(Upper)
    @State private var holdDuration = 0.0           // 유지시간
    @State private var lastHoldTick: Date?          // 바로 직전에 시간을 쟀던 과거의 타이머 시점
    @State private var isClear = false              // 클리어 여부
    @State private var clearedLevelCount = 0        // 클리어한 레벨
    @State private var holdStartDate: Date?         // 범위 안에 처음 들어온 시각 저장 - 현재 시간과 비교
    @State private var levels: [Stage2LockLevel] = []       // 레벨(총 3개)
    @State private var currentLevelIndex = 0        // 현재 레벨
    
    var holdGoal: Double = 3.0          // 목표 유지시간(기획 시 3초)
    var onClear: (() -> Void)?
    
    // 유지시간 시간 재는 타이머 - 0.05틱마다 메인 쓰레드에 현재 시각 신호를 보내주는 타이머
    private let holdticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    
    // 레벨이 클리어되는 조건(화면에 접촉 포함)
    private var isHoldingValidPose: Bool {
        pencil.state.isTouching &&              // 화면에 펜슬을 접촉하고 있는가?
        pencil.state.location != nil &&         // 현재 펜슬의 위치값이 nil이 아닌가?
        tiltRangeSatisfied &&                   // Tilt 목표 범위를 만족하는가?
        rollRangeSatisfied                      // Barrel Roll 목표 범위를 만족하는가?
    }
    
    var body: some View {
        GeometryReader { proxy in       // 현재 화면 크기 알려주는 역할(부모 뷰에 따라 자식 뷰 결정)
            landscapeLayout(size: proxy.size)       // 가로모드 기준
        }
        .onReceive(holdticker) { date in    // holdticker로부터 신호가 오면
            updateHoldProgress(at: date)    // 현재 시각(date)을 받아서 updateHoldProgress 실행(3초 버티는지 검사)
        }
        
        // 화면에 펜슬을 접촉시키고 있지 않으면 유지시간 리셋
        .onChange(of: !pencil.state.isTouching) { _, _ in resetChallenge() }
        
        // 목표 범위가 바뀌는 경우 유지시간 리셋
        .onChange(of: tiltRangeLower) { _, _ in resetChallenge() }
        .onChange(of: tiltRangeUpper) { _, _ in resetChallenge() }
        .onChange(of: rollRangeLower) { _, _ in resetChallenge() }
        .onChange(of: rollRangeUpper) { _, _ in resetChallenge() }
        
        .onAppear {     // 시작 시 레벨 생성
            if levels.isEmpty {
                levels = makeLevels()
                applyCurrentLevel()
            }
        }
        .onDisappear {
            KeySound.stop()  // 스테이지 나갈 시, 음성 멈추도록
        }
        
        .stageHaptics(haptics)
    }
    
    private func landscapeLayout(size: CGSize) -> some View {
        _ = min(size.width * 0.48, 520)
        
        return HStack(alignment: .top, spacing: 18) {
            gaugePanel      // 목표와 현재 Tilt/Barrel Roll값 확인 가능한 패널
            
            // 실제 펜슬을 접촉시키는 캔버스
            Stage2LockCanvasView(
                state: pencil.state,
                holdDuration: holdDuration,
                holdGoal: holdGoal,
                isClear: isClear
            )
            .frame(width: 100, height: 150)
            .overlay {      // 캔버스 안에만 펜슬 입력을 받게 하기 위해 이곳에 사용
                RealPencilFeeder()
            }
            .position(x: size.width * 0.275, y: size.height * 0.43)
        }
        .padding(20)
    }
    
    private var gaugePanel: some View {     // 목표와 현재 Tilt/Barrel Roll값 확인 가능한 패널
        VStack(alignment: .center, spacing: 20) {
            Spacer()        // 타이틀에 시각화가 너무 가까이 있어 사용
            // 클리어한 레벨 시각화
            HStack(spacing: 10) {
                ForEach(0..<max(levels.count, 3), id: \.self) { index in
                    Circle()
                        .fill(index < clearedLevelCount ? .green : .stage2PanelBackground.opacity(0.4))
                        .frame(width: 25, height: 25)
                }
            }
            
            VStack(spacing: 20) {       // Tilt, Barrel Roll 원형 게이지
                Stage2PencilRangeGauge(
                    title: "기울이기",                       // 어떤 게이지인지 나타내는 이름
                    value: pencil.state.tiltDegrees,        // Tilt 현재 값
                    isSatisfied: tiltRangeSatisfied,        // 목표 Tilt 범위에 현재 tilt 값이 들어가있는가
                    targetLower: min(tiltRangeLower, tiltRangeUpper),
                    targetUpper: max(tiltRangeLower, tiltRangeUpper),
                    gaugeRange: 0...70,     // Tilt 범위는 0도~70도
                    color: .stage2TiltPanel,
                    circleStrokeColor: .stage2TiltCircleStroke
                )
                
                Stage2PencilRangeGauge(
                    title: "돌리기",       // 어떤 게이지인지 나타내는 이름
                    value: pencil.state.barrelRollDegrees,      // Barrel Roll 현재 값
                    isSatisfied: rollRangeSatisfied,            // 목표 Barrel Roll 범위에 현재 Barrel Roll 값이 들어가있는가
                    targetLower: PencilAngle.normalizedDegrees(rollRangeLower),
                    targetUpper: PencilAngle.normalizedDegrees(rollRangeUpper),
                    gaugeRange: 0...360,        // Barrel Roll 범위는 0도~360도
                    color: .stage2BarrelRollPanel,
                    circleStrokeColor: .stage2BarrelRollCircleStroke
                    
                )
            }
            .frame(maxHeight: .infinity)
        }
        .padding(20)
        .frame(width: 250)      // 패널 감싸는 프레임(가로폭 고정)
    }
    
    private var tiltRangeSatisfied: Bool {      // PencilRangeGauge에서 범위를 만족했는지 확인하는 용도로 사용(Tilt)
        // tiltRangeLower, tiltRangeUpper 이름에 상관없이 설정된 두 변수 중 작은 값을 범위의 최솟값, 큰 값을 범위의 최댓값으로 설정
        let lower = min(tiltRangeLower, tiltRangeUpper)
        let upper = max(tiltRangeLower, tiltRangeUpper)
        
        // 현재 Tilt가 범위 사이인지 판단하여 return
        return pencil.state.tiltDegrees >= lower && pencil.state.tiltDegrees <= upper
    }
    
    private var rollRangeSatisfied: Bool {      // PencilRangeGauge에서 범위를 만족했는지 확인하는 용도로 사용(Barrel Roll)
        circularRangeContains(      // Barrel Roll 목표 범위에 현재 값이 있으면 true를 반환하는 함수
            value: pencil.state.barrelRollDegrees,
            lower: rollRangeLower,
            upper: rollRangeUpper
        )
    }
    
    // 시간을 누적하고 3초 버텼는지 검사하는 함수
    private func updateHoldProgress(at date: Date) {
        guard isHoldingValidPose else {       // 레벨 클리어 조건을 하나라도 만족하지 못한 경우
            holdStartDate = nil         // 범위 안에 처음 들어온 시각 = nil
            holdDuration = 0        // 누적시간 = 0
            KeySound.stop() // 조건 벗어날 시 정지
            isClear = false
            return
        }
        KeySound.start() // 키 따기 시작할 시, 음성 나오도록
        haptics.pulse()
        
        if holdStartDate == nil {       // 범위 안에 들어온 적이 없는 경우
            holdStartDate = date
        }

        holdDuration = min(holdGoal, date.timeIntervalSince(holdStartDate ?? date))

        if holdDuration >= holdGoal && !isClear {
            isClear = true
            completeCurrentLevel()
        }
    }
    
    // 범위 벗어나는 경우 유지시간 리셋
    private func resetChallenge(keepingTick: Bool = false) {
        holdDuration = 0        // 유지시간 -> 0
        isClear = false         // 성공 판정 -> false
        
        if !keepingTick {
            lastHoldTick = nil      // 시간 기준점을 nil로 설정
        }
    }
    
    // 현재 레벨 클리어 시 다음 레벨 또는 스테이지 클리어
    private func completeCurrentLevel() {
        clearedLevelCount += 1
        UINotificationFeedbackGenerator().notificationOccurred(.success)        // 성공 피드백

        if currentLevelIndex < levels.count - 1 {
            currentLevelIndex += 1
            applyCurrentLevel()
        } else {
            onClear?()
        }
    }
    
    // 레벨이 바뀌는 경우 현재 목표 범위 state에 적용
    private func applyCurrentLevel() {
        guard levels.indices.contains(currentLevelIndex) else { return }
        
        let level = levels[currentLevelIndex]
        tiltRangeLower = level.tiltLower
        tiltRangeUpper = level.tiltUpper
        rollRangeLower = level.rollLower
        rollRangeUpper = level.rollUpper
        
        resetChallenge()
    }
    
    // 랜덤으로 생성된 목표 범위로 레벨 생성
    private func makeLevels() -> [Stage2LockLevel] {
        [
            makeRandomLevel(tiltWidth: 10, rollWidth: 50), // Lv1 쉬움
            makeRandomLevel(tiltWidth: 5, rollWidth: 25), // Lv2 중간
            makeRandomLevel(tiltWidth: 3, rollWidth: 10)   // Lv3 어려움
        ]
    }
    
    // 랜덤으로 목표 범위 만들기
    private func makeRandomLevel(tiltWidth: Double, rollWidth: Double) -> Stage2LockLevel {
        let tiltStart = Double.random(in: 5...(70 - tiltWidth))
        let rollStart = Double.random(in: 0..<360)

        return Stage2LockLevel(
            tiltLower: tiltStart,
            tiltUpper: tiltStart + tiltWidth,
            rollLower: rollStart,
            rollUpper: (rollStart + rollWidth).truncatingRemainder(dividingBy: 360)
        )
    }
}

// 정규화 : 400도, -90도 등 복잡한 숫자를 0~360도 사이로 각도 변환
private func circularRangeContains(value: Double, lower: Double, upper: Double) -> Bool {
    let normalizedValue = PencilAngle.normalizedDegrees(value)      // 현재 각도 정규화
    let normalizedLower = PencilAngle.normalizedDegrees(lower)      // 목표 범위 최솟값 정규화
    let normalizedUpper = PencilAngle.normalizedDegrees(upper)      // 목표 범위 최댓값 정규화

    if normalizedLower <= normalizedUpper {     // 범위 시작 각도 <= 범위 끝 각도(일반적 경우)
        // 범위 시작 각도 <= 현재 각도 <= 범위 끝 각도 ; 범위 사이에 있으면 true 반환
        return normalizedValue >= normalizedLower && normalizedValue <= normalizedUpper
    }
    
    // 원이 끊기는 지점을 넘어간 경우(범위 시작 각도 >= 범위 끝 각도)
    // 예시 : 시작 300도 - 끝 60도일 경우
    // 시작 300 ~ (360) 사이 or (0) ~ 끝 60 사이에 현재 값이 있으면 true 반환
    return normalizedValue >= normalizedLower || normalizedValue <= normalizedUpper
}

