//
//  IntroStory.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/5/26.
//

import Foundation
import SwiftUI


let introStory: [StoryPage] = [
    //컷 1
    StoryPage(
        background: "bg_prelude1", //일단 검은색으로
        panel: StoryPanel(text: "1922년 Apple Developer Academy @ Egypt..")
        ),
    
    // 컷 2
        StoryPage(
            background: "bg_prelude2",
            panel: StoryPanel(text: "세상은 아직 몰랐다. 전설의 유물, 코리카멘의 무덤이 존재한다는 사실을..")
        ),
    // 컷 3
    StoryPage(
        background: "bg_prelude3",
        panel: StoryPanel(text: "그.. 요즘 루미 멘토 조금 이상하지 않아요?")
    ),
    // 컷 4 -> 루미 멘토 추가해야함
    StoryPage(
        background: "bg_prelude4",
        panel: StoryPanel(text: "그니까요! 막 금목걸이에 금애플워치까지...")
    ),
    // 컷 5 -> 루미 멘토 추가해야함
    StoryPage(
        background: "bg_prelude5",
        panel: StoryPanel(text: "저 어제 봤어요 퇴근할 때 삽들고 나가는 거. **이건 100% 도굴이에요.** ")
    ),
    // 컷 6
    StoryPage( //-> notice 추가해야함
        background: "bg_prelude6"),
    
    // 컷 7
    StoryPage(
        background: "bg_prelude7",
        panel: StoryPanel(text: "보자보자..내 통장잔고....")
    ),
    // 컷 8
    StoryPage(
        background: "bg_prelude8",
        panel: StoryPanel(text: "143원...?!??!! 학습지원금 110만원은 어디로...")
    ),
    // 컷 9 -> 루미 멘토 추가해야함
    StoryPage(
        background: "bg_prelude9",
        panel: StoryPanel(text: "**코리카멘 전설의 황금 유물.. 찾기만 하면 평생 놀고 먹고 살 수 있을텐데..**")
    ),
    // 컷 10
    StoryPage(
        background: "bg_prelude10",
        ),
    // 컷 11
    StoryPage(
        background: "bg_prelude11",
        ),
    
    // 컷 12 -> 루미 멘토 추가해야함
    StoryPage(
        background: "bg_prelude12",
        panel: StoryPanel(text: "좋아.. **루미보다 먼저 간다**")
    ),
    // 컷 13
    StoryPage(
        background: "bg_prelude13"),
    
    // 컷 14
    StoryPage(
        background: "bg_prelude14",
        panel: StoryPanel(text: "이제 들어간다..")
    ),
    // 컷 15 (전환 씬)
    StoryPage(
        background: "bg_prelude15", transition: .fade(.black,1.0)
    ),
    // 컷 16
    StoryPage(
        background: "bg_prelude16",
        panel: StoryPanel(text: "저건 뭐지..?")
    ),
    // 컷 17
    StoryPage(
        background: "bg_prelude17",
        panel: StoryPanel(text: "왕의 보호막을 깨는 자, 엄청난 부를 얻게 되리라...?")
    ),
    // 컷 18 (전환 씬)
    StoryPage(
        background: "bg_prelude18", transition: .fade(.white,1.0)
    ),
    // 컷 19 (전환 씬)
    StoryPage(
        background: "bg_prelude19", transition: .fade(.white,1.0)
    )

]
let stage1Story: [StoryPage] = [
    //컷 1
    StoryPage(background: "bg_stage1_1"),
    //컷 2
    StoryPage(
        background: "bg_stage1_2", panel: StoryPanel(text: "철컥철컥.. 안열리는데..? 아 고대 이집트 자물쇠구나")
    ),
    //컷 3
    StoryPage(
        background: "bg_stage1_3", panel: StoryPanel(text: "어.? 섬세하지 못한 자, **왕의 재산에 닿을 수 없다...?**")
    )
    ]

let stage2Story: [StoryPage] = [
    //컷 1
    StoryPage(background: "bg_stage2_1"),
    //컷 2
    StoryPage(
        background: "bg_stage2_2", panel: StoryPanel(text: "학습지원금 탈출이 얼마 남지 않았다.")
    ),
    //컷 3
    StoryPage(
        background: "bg_stage2_3", panel: StoryPanel(text: "우선 관의 문을 빨리 열어야 한다.")
    ),
    //컷 4 -> 파피루스 이펙트 필요
    StoryPage(
        background: "bg_stage2_4",
        overlays: [
            StoryOverlay(image: "layout_stage2_prelude_4", position: .bottomLeading, appearDelay: 0.3)
        ], //파피루스 위치 -> 좌측 하단
        panel: StoryPanel(text: "어 이건 뭐지/././??")
    ),
    //컷 5
    StoryPage(
        background: "bg_stage2_5"),
    
    //컷 6
    StoryPage(
        background: "bg_stage2_6", panel: StoryPanel(text: "이집트 사람들 말 겁나 많네")
    ),
    //컷 7
    StoryPage(
        background: "bg_stage2_6", panel: StoryPanel(text: "그래 이제는 문을 열어보자. **왕의 보물을 탐내는 자, 시련의 실에 갇히리라!**")
    ),

]
