//
//  Stage2PencilRangeGauge.swift
//  C3_Korikamen
//
//  Created by Yourim on 6/5/26.
//
// 원형으로 게이지 나타내는 뷰
// 내 점수가 전체에서 몇 %인지 계산 (0에서 1 사이의 값으로 변환)
// 그 %만큼 화면에 동그란 호(Arc) 그리기

import SwiftUI

struct Stage2PencilRangeGauge: View {
    let title: String       // 어떤 게이지인지 나타내는 타이틀
    let value: Double       // 현재 입력받는 펜슬 값(Tilt, Barrel Roll)
    let isSatisfied: Bool       // 목표 범위 안에 현재 입력값이 들어가있는지 여부
    let targetLower: Double     // 목표 범위(Lower)
    let targetUpper: Double     // 목표 범위(Upper)
    let gaugeRange: ClosedRange<Double>     // 게이지 범위(Tilt : 0~90, Barrel Roll : 0~360)
    let color: Color        // 게이지 색상
    let circleStrokeColor: Color

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                // tilte / 목표 범위에 들어가있는지에 따른 시각적 피드백(아이콘) - 추후 방식 수정할 예정(Hi-fi 참고)
                Label(title, systemImage: isSatisfied ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.headline)
                    .foregroundStyle(isSatisfied ? .green : .primary)
            }
            .padding(.bottom, 15)

            ZStack {        // 원형 게이지 표시
                Circle()        // 범위 밑에 깔리는 원 테두리
                    .stroke(circleStrokeColor, lineWidth: 10)

                rangeArc    // 목표 범위를 시각적으로 보여주는 역할(범위만 주황색으로 표시)

                PencilGaugeNeedle(angle: valueAngle, color: color)

                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.bottom, 10)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.stage2PanelBackground.opacity(0.4), in: RoundedRectangle(cornerRadius: 20))
    }
    
    // 현재 펜슬값(value)이 전체 범위에서 어디쯤(%) 있는지를 구해서 나중에 바늘(valueAngle)을 돌릴 때 쓰려고 만든 것
    private var progress: CGFloat {     // 실제 펜슬 데이터 -> 비율(0~1)
        let span = gaugeRange.upperBound - gaugeRange.lowerBound        // 총 길이(큰값-작은값)
        return lockpickClamped(     // 범위를 벗어나도 0~1 사이로 강제로 만드는 안전장치
            CGFloat((value - gaugeRange.lowerBound) / span),
            lower: 0,
            upper: 1
        )
    }
    
    // 현재 값을 나타내는 바늘에 사용(PencilGaugeNeedle)
    private var valueAngle: Angle {     // 비율 -> 각도로 다시 바꾸는 역할
        .degrees(Double(progress) * 360)
    }
    
    // 범위를 시각적으로 보여주는 역할 - Barrel Roll 목표 범위가 360도를 넘어가는 예외 상황 처리 포함
    // trim 사용 - 원의 일부분만 잘라서 보여준다
    @ViewBuilder
    private var rangeArc: some View {
        let lower = rangeProgress(for: targetLower)     // 실제 값 -> 비율
        let upper = rangeProgress(for: targetUpper)

        if lower <= upper {     // 일반적인 경우(lower가 작은 경우)
            Circle()        // 원을 그린 후 trim으로 일부만 잘라 보여주는 방식
                .trim(from: lower, to: upper)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        } else {        // lower가 upper보다 큰 경우(원이 한 바퀴 넘어가는 경우)
            Circle()
                .trim(from: lower, to: 1)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0, to: upper)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
    
    // 목표 범위의 시작(targetLower), 끝(targetUpper)가 각각 몇 % 지점인지 구해서 trim에 넘겨주려고 만든 것(현재 펜슬값 X)
    // 실제 값 -> 비율 trim은 0~1 사이 값만 받기 때문에 사용
    private func rangeProgress(for value: Double) -> CGFloat {
        let span = gaugeRange.upperBound - gaugeRange.lowerBound
        return lockpickClamped(
            CGFloat((value - gaugeRange.lowerBound) / span),
            lower: 0,
            upper: 1
        )
    }
}

private func lockpickClamped<T: Comparable>(_ value: T, lower: T, upper: T) -> T {
    min(max(value, lower), upper)       // 펜슬 값이 범위를 벗어나도 0~1 사이로 강제로 만드는 안전장치
}



// 실제 펜슬 입력값을 바늘로 원형 게이지에 표현하는 뷰
struct PencilGaugeNeedle: View {
    let angle: Angle        // valueAngle - 현재 펜슬의 각도 값을 받아올 예정
    let color: Color        // 바늘 색

    var body: some View {
        GeometryReader { geometry in
            // 화면의 가로 길이와 세로 길이 중 더 짧은 쪽을 기준(side)으로 설정 - (바늘 길이, 원 크기 설정을 위함)
            let side = min(geometry.size.width, geometry.size.height)
            Capsule()       // 끝이 둥근 직사각형으로 바늘 생성
                .fill(color)
                .frame(width: 6, height: side * 0.42)       // 두께 : 6, 길이 : 전체 원 크기*0.42
                // 가로는 화면 정중앙에, 세로는 정중앙에서 바늘 길이의 절반만큼 위로 올린 위치에 배치(바늘 끝이 중앙에 오도록)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - side * 0.21)
                .rotationEffect(angle, anchor: .center)     // 입력 각도에 따라 바늘 회전
        }
    }
}
