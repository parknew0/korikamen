//
//  Stage3GameManager.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/2/26.
//  Stage3 로직 전담

import Foundation
import Combine

final class Stage3GameManager: ObservableObject {
    
    // MARK: - 보관할 값들 정리

    // Scene#1 (관 뚜껑 열기)
    // 씬 전환을 구분하기 위한 변수 선언
    
    enum Stage3Scene { case openingLid, removingWeb } //씬 종류
    @Published private(set) var scene: Stage3Scene = .openingLid // 현재 씬
    @Published private(set) var lidProgress: Double = 0 // 뚜껑 진행도(0 = 닫힘, 1 = 완전 열림)
    private let openThreshold = 0.5 // 50% 이상 열리면 열리도록 임계값 추가

    //Scene#2 (스퀴즈로 거미줄 지우기)
    
    @Published private(set) var gauge: Double = 0 // 게이지 현재 값(0~1)
    @Published private(set) var targetMin : Double = 0.75 // 목표 범위 최소 (1라운드 고정으로 설정)
    @Published private(set) var targetMax : Double = 0.85 // 목표 범위 최대 (1라운드 고정으로 설정)
    @Published private(set) var successCount: Int = 0 // 성공횟수(0~5)
    @Published private(set) var webLayerIndex: Int = 5 // 거미줄 레이어의 남은 겹 (5 -> 0)
    
    let requiredSuccessCount: Int = 5 //클리어에 필요한 성공 횟수
    
    private let gaugeStep = 0.0275 //50ms당 증가량 (해당 클래스에서만 보이도록)
    private let tick = 0.05 //타이머 간격
    private var cancellable : AnyCancellable? //Combine 타이머를 담기 위함
    
    //계산되는 값
    private let tolerance = 0.03 //판정 여유
    var isInTarget : Bool { gauge >= targetMin && gauge <= targetMax + tolerance} // 게이지가 현재 목표 범위 안에 있는지 여부 + 판정 완화(max 범위만 후하게 처리) 
    var isCleared : Bool { successCount >= requiredSuccessCount } // 클리어 여부
    
    // MARK: - 함수들
    
    // Scene#1 함수
    // 애플펜슬로 드래그 시, 뚜껑에 대한 진행도 갱신 함수
    func updateLid(progress: Double) { //진행도 0~1 값 호출
        guard scene == .openingLid else { return } //Scene1(뚜껑 열기) 중일 때만 진행. 이미 열려서 Scene2면 무시.
        lidProgress = min(1,max(0,progress)) // 0~1 사이로 제한 + 저장
        
    }
    //뚜껑에서 손 떼는 순간 판정하는 함수
    func endLidDrag() {
        guard scene == .openingLid else { return } //Scene1(뚜껑 열기) 중일 때만
        if lidProgress >= openThreshold { //50% 이상 열면
            lidProgress = 1 //완전히 열리도록
            scene = .removingWeb //다음 씬으로 이동
        } else {
            lidProgress = 0 // 스프링 복귀
        }
    }
    // 스퀴즈 시작 시 동작되는 함수 (게이지 증가 타이머가 시작되도록)
    func beginSqueeze() {
        guard cancellable == nil else { return } // 타이머가 돌고 있으면 중복 시작이 안되도록 방지
        cancellable = Timer.publish(every: tick, on: .main, in: .common) // tick(50ms)마다 main에 신호를 보내는 common 모드 타이머 생성.
            .autoconnect() //자동 켜기
            .sink { [weak self] _ in self?.step() } // 신호가 올 때마다 step() 실행
    }
    // 게이지를 올리는 함수
    private func step() {
        gauge = min(1.0, gauge + gaugeStep) // +2.75%, 1.0은 넘지 않도록.
    }
    // 스퀴즈 손 뗐을 때 호출되는 함수
    func endSqueeze() {
        //guard !isCleared else { return } ->  이미 클리어했을 시, 더 이상 처리 안되도록 안전장치 추가함 (이건 해보고 버그 있으면 추가할 예정)
        cancellable?.cancel() //타이머 정지
        cancellable = nil // 값 비우기 -> 다음 스퀴즈 값 불러올 수 있도록
        
        if isInTarget {
            success()
        } // 게이지가 목표 범위 안이면 성공 처리
        else {
            fail()
        } // 실패 처리
    }
    // 성공 처리 함수
    private func success() {
        successCount += 1 // 성공 횟수 1 증가
        webLayerIndex -= 1 // 거미줄 제거
        gauge = 0  // 게이지 리셋
        
        if !isCleared { // 클리어 전 기준
            randomizeRange() // 다음 라운드 목표 범위 랜덤 변경되도록
        }
    }
    // 실패 처리 함수 ( 게이지만 리셋되고, 기존 범위는 유지 )
    private func fail() {
        gauge = 0 }
    //성공할 때마다 다음 라운드의 목표 범위를 랜덤하게 만드는 함수 ( 2 ~ 5 라운드용 ).
    private func randomizeRange() {
        let width = Double.random(in: 0.06...0.12)// 범위 폭 :  6~12% 정도 (추후 테스트)
        let lower = Double.random(in: 0...(1-width)) // 시작 위치 (맨 꼭대기 넘지 않도록)
        
        targetMin = lower
        targetMax = lower + width
    }
}


