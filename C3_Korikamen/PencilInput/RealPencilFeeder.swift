//
//  RealPencilFeeder.swift
//  C3_Korikamen
//
//  Created by Yourim on 6/6/26.
//
//  실기기 어댑터

import UIKit
import SwiftUI

struct RealPencilFeeder: UIViewRepresentable {
    @EnvironmentObject private var pencil: PencilInput

    func makeUIView(context: Context) -> PencilCaptureView {
        let view = PencilCaptureView()
        view.pencil = pencil
        return view
    }

    func updateUIView(_ uiView: PencilCaptureView, context: Context) {
        uiView.pencil = pencil
    }
}

final class PencilCaptureView: UIView {
    var pencil: PencilInput?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        isMultipleTouchEnabled = false
        
        let hover = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
        addGestureRecognizer(hover)
        
        let pencilInteraction = UIPencilInteraction(delegate: self)
        addInteraction(pencilInteraction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTouch(touches.first)
        print("touchesBegan")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTouch(touches.first)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouch()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouch()
    }
    
    private func updateTouch(_ touch: UITouch?) {
        guard let touch, touch.type == .pencil else { return }
        
        var state = pencil?.state ?? PencilState()
        state.location = touch.location(in: self)
        state.isTouching = true
        state.tiltDegrees = 90 - touch.altitudeAngle.degrees
        state.barrelRollDegrees = PencilAngle.normalizedDegrees(touch.rollAngle.degrees)
        
        pencil?.state = state
        print("Apple Pencil 감지")
    }
    
    // touch 끝났을 경우
    private func endTouch() {
        var state = pencil?.state ?? PencilState()
        state.isTouching = false
        state.isHovering = false
        state.location = nil

        print("터치 끗")
        
        pencil?.state = state
    }
    
    @objc private func handleHover(_ recognizer: UIHoverGestureRecognizer) {
        guard recognizer.state == .began || recognizer.state == .changed else {
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
    func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveTap tap: UIPencilInteraction.Tap) {
        var state = pencil?.state ?? PencilState()
        state.doubleTapCount += 1
        
        if let pose = tap.hoverPose {
            applyHoverPose(pose, to: &state)
        }
        
        pencil?.state = state
    }
    
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

