//
//  RealPencilFeeder.swift
//  C3_Korikamen
//
//  Created by Yourim on 6/6/26.
//
//  실기기 어댑터
//  UIKit에서 실제 Apple Pencil 입력을 받고, PencilState로 변환해서 PencilInput.state에 넣는 목적

import UIKit
import SwiftUI

struct RealPencilFeeder: UIViewRepresentable {      // SwiftUI와 UIKit 연결용
    @EnvironmentObject private var pencil: PencilInput

    func makeUIView(context: Context) -> PencilCaptureView {        // 최초 호출(1번)
        let view = PencilCaptureView()
        view.pencil = pencil
        return view
    }

    func updateUIView(_ uiView: PencilCaptureView, context: Context) {      // SwiftUI 갱신될 때마다 호출
        uiView.pencil = pencil
    }
}

final class PencilCaptureView: UIView {     // Pencil 입력을 받는 투명한 UIView
    var pencil: PencilInput?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true         // 터치 입력
        isMultipleTouchEnabled = false          // 동시 터치 무시
        
        let hover = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))          // Hover 감지
        addGestureRecognizer(hover)
        
        let pencilInteraction = UIPencilInteraction(delegate: self)         // Apple Pencil Pro의 Double Tap, Squeeze 받는 역할
        addInteraction(pencilInteraction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {         // 화면에 펜슬 접촉 시 updateTouch 실행
        updateTouch(touches.first)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {         // 펜이 움직이는 동안 updateTouch 계속 호출
        updateTouch(touches.first)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {         // 펜을 떼는 순간 endTouch 실행
        endTouch()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouch()
    }
    
    private func updateTouch(_ touch: UITouch?) {
        guard let touch, touch.type == .pencil else { return }      // 손가락을 제외한 pencil 타입의 터치만 처리
        
        var state = pencil?.state ?? PencilState()
        state.location = touch.location(in: self)       // 현재 좌표
        state.isTouching = true         // 접촉 여부
        
        // 기존 altitudeAngle 입력(0° = 눕힘, 90° = 세움)를 계약 사항에 따라 Tilt(0° = 세움, 90° = 눕힘)으로 정의
        state.tiltDegrees = 90 - touch.altitudeAngle.degrees
        state.barrelRollDegrees = PencilAngle.normalizedDegrees(touch.rollAngle.degrees)        // 펜의 회전 각도 정규화
        
        pencil?.state = state
    }
    
    // touch 끝났을 경우
    private func endTouch() {
        var state = pencil?.state ?? PencilState()
        state.isTouching = false
        state.isHovering = false
        state.location = nil
        
        pencil?.state = state
    }
    
    // hover 상태
    @objc private func handleHover(_ recognizer: UIHoverGestureRecognizer) {
        guard recognizer.state == .began || recognizer.state == .changed else {     // 포인터가 등록된 뷰의 영역 안으로 처음 들어왔을때/이동할 때가 아닐 경우 실행
            var state = pencil?.state ?? PencilState()
            state.isHovering = false

            if !state.isTouching {
                state.location = nil
            }
            return
        }

        var state = pencil?.state ?? PencilState()

        state.location = recognizer.location(in: self)
        state.isHovering = true
        state.isTouching = false
        state.tiltDegrees = 90 - recognizer.altitudeAngle.degrees
        state.barrelRollDegrees = PencilAngle.normalizedDegrees(recognizer.rollAngle.degrees)

        pencil?.state = state
    }
    
}

extension PencilCaptureView: UIPencilInteractionDelegate {
    // 더블 탭 시 doubleTapCount +1
    func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveTap tap: UIPencilInteraction.Tap) {
        var state = pencil?.state ?? PencilState()
        state.doubleTapCount += 1
        
        if let pose = tap.hoverPose {
            applyHoverPose(pose, to: &state)
        }
        
//        pencil?.state = state
    }
    
    // Squeeze 시 알맞은 스퀴즈 상태 저장
    func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze) {
        var state = pencil?.state ?? PencilState()
        
        switch squeeze.phase {
        case .began: state.squeezePhase = .began
        case .changed: state.squeezePhase = .changed
        case .ended: state.squeezePhase = .ended
        default: state.squeezePhase = .none
            
        }
        
        if let pose = squeeze.hoverPose {
            applyHoverPose(pose, to: &state)
        }

        pencil?.state = state

    }
    
    // Squeeze, Double Tap 시 기본적으로 제공하는 정보를 쉽게 활용하기 위한 함수? - 정확한 이해를 위해 루미에게 질문 예정
    fileprivate func applyHoverPose(_ pose: UIPencilHoverPose, to state: inout PencilState) {
        state.location = pose.location
        state.isHovering = true
        state.isTouching = false
        state.tiltDegrees = 90 - pose.altitudeAngle.degrees
        state.barrelRollDegrees = PencilAngle.normalizedDegrees(pose.rollAngle.degrees)
    }
}

// 라디안 -> 도(degree) 단위 변환하기 위함 - 원래 pencil 입력은 라디안으로 각도 받기 때문
private extension CGFloat {
    var degrees: Double {
        Double(self) * 180 / .pi
    }
}

