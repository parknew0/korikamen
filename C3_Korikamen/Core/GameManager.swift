//
//  GameManager.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//
//  게임 전체 진행(단계 전환·경과시간)을 관리하는 두뇌.
//  진실의 원천은 GKStateMachine, phase는 SwiftUI 표시용 거울.
//

import GameplayKit
import Combine

enum GamePhase: Equatable {
    case main          // 메인(타이틀) 화면 — 시작 지점 + 실패 시 돌아오는 곳
    case stage(Int)
    case ending
}

final class GameManager: ObservableObject {
    @Published private(set) var phase: GamePhase = .main
    @Published private(set) var failedStage: Int? = nil

    private(set) var stageTimes: [Int: Double] = [:]
    var totalPlayTime: Double { stageTimes.values.reduce(0, +) }

    private lazy var machine = GKStateMachine(states: [
        MainState(self), Stage1State(self), Stage2State(self),
        Stage3State(self), EndingState(self),
    ])

    init() { machine.enter(MainState.self) }

    func recordTime(stage: Int, elapsed: Double) { stageTimes[stage] = elapsed }

    func advance() {
        switch phase {
        case .main:     machine.enter(Stage1State.self)
        case .stage(1): machine.enter(Stage2State.self)
        case .stage(2): machine.enter(Stage3State.self)
        case .stage(3): machine.enter(EndingState.self)
        case .ending:   machine.enter(MainState.self)
        case .stage:    break
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

    fileprivate func updatePhase(_ p: GamePhase) { phase = p }
}

class GameBaseState: GKState {
    weak var manager: GameManager?
    init(_ manager: GameManager) { self.manager = manager; super.init() }
}
final class MainState: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.main) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == Stage1State.self }
}
final class Stage1State: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.stage(1)) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == Stage2State.self || s == MainState.self }
}
final class Stage2State: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.stage(2)) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == Stage3State.self || s == MainState.self }
}
final class Stage3State: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.stage(3)) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == EndingState.self || s == MainState.self }
}
final class EndingState: GameBaseState {
    override func didEnter(from p: GKState?) { manager?.updatePhase(.ending) }
    override func isValidNextState(_ s: AnyClass) -> Bool { s == MainState.self }
}
