//
//  GameManager.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//
//  게임 전체 진행(단계 전환·경과시간)을 관리하는 두뇌.
//  진실의 원천은 GKStateMachine, phase는 SwiftUI 표시용 거울.
//  인트로 추가됨@@@

import GameplayKit
import Combine

enum GamePhase: Equatable {
    case main          // 메인(타이틀) 화면 — 시작 지점 + 실패 시 돌아오는 곳
    case intro // 추가
    case stage(Int)
    case interlude(Int) // 추가: 스테이지 후 스토리(1 = stage 1)
    case ending
}

final class GameManager: ObservableObject {
    @Published private(set) var phase: GamePhase = .main
    @Published private(set) var failedStage: Int? = nil

    private(set) var stageTimes: [Int: Double] = [:]
    var totalPlayTime: Double { stageTimes.values.reduce(0, +) }
    
    private var stageStartTime: Date? // 현재 스테이지에 들어온 시각
    
    private lazy var machine = GKStateMachine(states: [
        MainState(self), IntroState(self), Stage1State(self), Stage2State(self),
        Stage3State(self), EndingState(self), Interlude1State(self), Interlude2State(self), //추가
    ])

    init() { machine.enter(MainState.self) }

    func recordTime(stage: Int, elapsed: Double) { stageTimes[stage] = elapsed }

    func advance() { // 전환 로직 추가
        //스테이지를 클리어하고 떠나는 순간, 걸린 시간 저장
        if case .stage(let n) = phase, let start = stageStartTime {
            recordTime(stage: n, elapsed: Date().timeIntervalSince(start))
        }
            switch phase {
            case .main:     machine.enter(IntroState.self)
            case .intro:    machine.enter(Stage1State.self)
            case .stage(1): machine.enter(Interlude1State.self)
            case .interlude(1): machine.enter(Stage2State.self)
            case .stage(2): machine.enter(Interlude2State.self)
            case .interlude(2): machine.enter(Stage3State.self)
            case .stage(3): machine.enter(EndingState.self)
            case .ending:   machine.enter(MainState.self)
            case .stage:    break
            case .interlude: break
            }
    }

    func fail() { if case .stage(let n) = phase { failedStage = n } }

    /// 같은 스테이지 처음부터 (뷰가 새로 마운트되며 리셋)
    func retry() { failedStage = nil }

    /// 실패/중단 시 메인 화면으로
    func goToMain() {
        failedStage = nil
        machine.enter(MainState.self)
    }

    fileprivate func updatePhase(_ p: GamePhase) { phase = p
        if case .stage = p { stageStartTime = Date() } // 스테이지 진입 시각 저장
    }
}

class GameBaseState: GKState {
    weak var manager: GameManager?
    init(_ manager: GameManager) { self.manager = manager; super.init() }
}

final class MainState: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.main) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == IntroState.self }
}

final class IntroState: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.intro) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == Stage1State.self } //intro 추가됨
}

final class Stage1State: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.stage(1)) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == Interlude1State.self || s == MainState.self }
}
final class Stage2State: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.stage(2)) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == Interlude2State.self || s == MainState.self }
}
final class Stage3State: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.stage(3)) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == EndingState.self || s == MainState.self }
}
final class EndingState: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.ending) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == MainState.self }
}

//스테이지 클리어 후 나올 스토리 관련 상태 로직 추가
final class Interlude1State: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.interlude(1)) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == Stage2State.self || s == MainState.self }
}
final class Interlude2State: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.interlude(2)) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == Stage3State.self || s == MainState.self }
}
