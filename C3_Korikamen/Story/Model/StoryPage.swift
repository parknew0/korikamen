//
//  StoryPage.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/5/26.
//  한 컷(화면) 전체 양식

import Foundation
import SwiftUI

//파일 정리
enum StoryTransition { // 컷이 시작될 때 화면을 덮었다 걷히는 전환효과 종류들
    case none
    case fade(Color, TimeInterval) //색 시간 지정 페이드
}

//텍스트 박스
struct StoryPanel {
    var image: String = "textbox" // 패널 배경 이미지(기본값)
    var text:  String // 대사
    var speaker: String? = nil //말하는 사람이 누군지(옵션)
}

//한 컷
struct StoryPage: Identifiable {
    let id = UUID()
    var background: String? = nil // 배경 이미지
    var overlays: [StoryOverlay] = [] // 연출 이미지들
    var panel: StoryPanel? = nil // 텍스트 박스
    var transition: StoryTransition = .fade(.black, 0.4) // 들어올 때 전환
    var autoAdvance: TimeInterval? = nil // 자동 넘김 대기시간
}


//예시) StoryPage(background: "prelude8_bg", panel: StoryPanel(text: "143원…?!??!!"))
