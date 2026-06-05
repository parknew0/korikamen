//
//  StoryOverlay.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/5/26.
// 연출용 이미지 양식 (한 컷에 여러 개 가능하도록)

import Foundation
import SwiftUI

// 오버레이 등장/반복 연출 종류들
enum StoryAnim {
    case none                    // 연출 x
    case fadeIn                  // 서서히 나타남
    case slide(from: Edge)       // 가장자리에서 미끄러져 등장 (.leading 등)
    case scale                   // 커지며 등장
    case loop                    // 반복 연출
    
}

struct StoryOverlay: Identifiable {
    let id = UUID()                   // 고유 번호
    var image: String                 // 이미지 이름
    var position: UnitPoint = .center // 화면 위치(기본적으로 가운데)
    var appearDelay: TimeInterval = 0 // 늦게 등장할 시간(기본 0)
    var animation: StoryAnim = .fadeIn  //등장 연출(기본적으로 fadein)
}
