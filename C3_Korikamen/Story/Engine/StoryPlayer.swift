//
//  StoryPlayer.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/5/26.
// 몇번째 컷인지, 해당 컷이 등장 중인지, 완성됐는지를 들고 탭에 반응해 스킵/다음을 판정하는 엔진

import Foundation
import Combine


final class StoryPlayer: ObservableObject {
    
    enum Beat : Equatable { case revealing, settled } //현재 컷이 등장 중인지, 다 떴는지 구분 (비교를 위해 Equatable 선언)
    @Published private(set) var index: Int = 0  //지금 몇 번쨰 컷
    @Published private(set) var beat: Beat = .revealing
    
    let pages:[StoryPage] // 받은 대본
    let onFinish : () -> Void // 마지막 컷 후 호출
    
    init(pages: [StoryPage], onFinish: @escaping () -> Void) {
        self.pages = pages
        self.onFinish = onFinish
    }
    
    // 화면 탭: 등장 중이면 스킵, 완성됐으면 다음으로 넘어가도록
    func tap() { // 글자,이미지가 서서히 뜰 때, 탭하면 바로 스킵되면서 즉시 완성되도록 하는 기믹 
        switch beat {
        case .revealing:
            beat = .settled // 스킵(연출 즉시 완성)
        case .settled:
            advance() //다음 컷
        }
    }
    
    // 연출이 끝나 완성 상태로(view가 등장 끝나면 호출되도록)
    func settle() {
        beat = .settled
    }
    
    // 다음 컷으로 이동하기, 이때 마지막이면 onFinish() 호출 후 종료하는 함수
    private func advance() {
        guard index + 1 < pages.count else {
            onFinish()
            return
        }
        index += 1
        beat = .revealing
    }
}
