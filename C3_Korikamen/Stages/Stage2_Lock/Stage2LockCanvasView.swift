//
//  Stage2LockCanvasView.swift
//  C3_Korikamen
//
//  Created by Yourim on 6/5/26.
//

import SwiftUI

struct Stage2LockCanvasView: View {        // 실제 펜슬을 접촉시키는 캔버스
    let state: PencilState
    
    let holdDuration: Double
    let holdGoal: Double
    let isClear: Bool

    var body: some View {       // 캔버스 디자인은 추후 수정 예정(Hi-Fi)
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: .systemGroupedBackground))

                Canvas { context, size in
//                    _ = Path()
//                    let _: CGFloat = 48
                    var path = Path()
                    let spacing: CGFloat = 48
                    
                    // 격자무늬
                    stride(from: CGFloat(0), through: size.width, by: spacing).forEach { x in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }

                    stride(from: CGFloat(0), through: size.height, by: spacing).forEach { y in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }

                    context.stroke(path, with: .color(.secondary.opacity(0.22)), lineWidth: 1)
                }

                // Mock으로 펜슬을 테스트하는 경우 현재 위치/Tilt/Barrel Roll을 간접적으로 표시하기 위한 마커 - 테스트 시 사용
                if let location = state.location {
                    pencilMarker(
                        at: clamped(location, in: geometry.size)
                    )
                }
            }
        }
    }
    
    //  프로그레스바와 현재 펜슬 위치 포인터
    private func pencilMarker(at point: CGPoint) -> some View {
        VStack(spacing: 8) {
            
            Circle()    // 현재 위치 원형 포인터로 표시
                .fill(.teal.opacity(0.4))
                .frame(width: 20, height: 20)

            ProgressView(       // 프로그레스바로 유지시간 게이지 표시
                value: holdDuration,
                total: holdGoal
            )
            .tint(isClear ? .green : .orange)
            .scaleEffect(x: 1, y: 5, anchor: .center)       // 기본 프로그레스바가 너무 얇아서 임시로 늘린 기능
            .frame(width: 120)
            .padding(15)
            
        }
        .position(point)
    }
    
    // 캔버스 범위를 벗어날 경우 0~캔버스 가로/세로길이 사이로 강제로 만드는 안전장치
    private func clamped(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), size.width),
            y: min(max(point.y, 0), size.height)
        )
    }
}
