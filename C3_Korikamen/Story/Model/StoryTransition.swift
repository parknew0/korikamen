//
//  StoryTransition.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/5/26.
//

import Foundation
import SwiftUI


enum StoryTransition { // 컷이 시작될 때 화면을 덮었다 걷히는 전환효과 종류들
    case none
    case fade(Color, TimeInterval) //색 시간 지정 페이드
}
