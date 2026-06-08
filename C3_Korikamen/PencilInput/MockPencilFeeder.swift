//
//  MockPencilFeeder.swift
//  C3_Korikamen
//
//  Created by Park on 6/2/26.
//
//  개발용 — 슬라이더로 PencilInput.state를 채워 시뮬레이터에서 펜슬 입력을 흉내낸다.
//  (RealPencilFeeder가 실기기에서 하는 일을 손으로 하는 가짜 버전. DEBUG 전용.)
//

#if DEBUG
import SwiftUI

struct MockPencilFeeder: View {
    @EnvironmentObject private var pencil: PencilInput
    @State private var padPoint: CGPoint? = nil   // 패드 내부 마커 표시용(로컬 좌표)
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if expanded { panel }
            Button { expanded.toggle() } label: {
                Label(expanded ? "닫기" : "Mock",
                      systemImage: expanded ? "xmark" : "slider.horizontal.3")
                    .font(.caption)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding()
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mock Pencil (개발용)").font(.caption).bold()
            touchPad
            slider("tilt",  $pencil.state.tiltDegrees, 0...90, "°")
            slider("roll",  $pencil.state.barrelRollDegrees, 0...360, "°")
            Toggle("hover", isOn: $pencil.state.isHovering).font(.caption2)
            Button {        // 더블 탭 테스트 버튼
                pencil.state.doubleTapCount += 1
            } label: {
                Label("double tap", systemImage: "hand.tap")
                    .font(.caption2)
            }
            squeezeButton
        }
        .padding(10)
        .frame(width: 220)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    /// 드래그 → 패드 양끝을 '화면 전체' 양끝에 대응시켜 location 설정.
    private var touchPad: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.15))
                Text("여기를 드래그 → 화면 전체 위치")
                    .font(.caption2).foregroundStyle(.secondary).allowsHitTesting(false)
                if pencil.state.isTouching, let p = padPoint {
                    ZStack {
                        Circle().fill(.orange.opacity(0.5))
                            .frame(width: 22)
                        Rectangle().fill(.orange).frame(width: 2, height: 22)
                            .rotationEffect(.degrees(pencil.state.barrelRollDegrees))
                    }
                    .position(p)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    // 패드 로컬 → 0~1 정규화 → 화면 좌표로 확대
                    let nx = min(max(v.location.x / geo.size.width, 0), 1)
                    let ny = min(max(v.location.y / geo.size.height, 0), 1)
                    let screen = UIScreen.main.bounds.size
                    pencil.state.location = CGPoint(x: nx * screen.width, y: ny * screen.height)
                    pencil.state.isTouching = true
                    padPoint = CGPoint(x: nx * geo.size.width, y: ny * geo.size.height) // 마커는 패드 안
                }
                .onEnded { _ in
                    pencil.state.isTouching = false
                    padPoint = nil
                })
        }
        .frame(height: 120)
    }

    private var squeezeButton: some View {
        Text(pencil.state.isSqueezing ? "스퀴즈 중…" : "스퀴즈 (누르고 있기)")
            .font(.caption2).frame(maxWidth: .infinity).padding(6)
            .background(pencil.state.isSqueezing ? Color.orange : Color.gray.opacity(0.25),
                        in: RoundedRectangle(cornerRadius: 8))
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in pencil.state.squeezePhase = .began }
                .onEnded   { _ in pencil.state.squeezePhase = .ended })
    }

    private func slider(_ name: String, _ value: Binding<Double>,
                        _ range: ClosedRange<Double>, _ unit: String) -> some View {
        let txt = unit.isEmpty ? String(format: "%.2f", value.wrappedValue)
                               : String(format: "%.0f", value.wrappedValue) + unit
        return HStack {
            Text(name).font(.caption2).frame(width: 42, alignment: .leading)
            Slider(value: value, in: range)
            Text(txt).font(.caption2).frame(width: 42, alignment: .trailing)
        }
    }
}
#endif
