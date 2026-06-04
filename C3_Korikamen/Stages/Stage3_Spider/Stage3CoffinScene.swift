//
//  Stage3CoffinScene.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/3/26.
//  SpriteKit 전용 scene ( 관 껍데기와 속 연결 )

import Foundation
import SpriteKit

final class Stage3CoffinScene: SKScene { // 관 그리기 위해 SKScene 표준 사용
    
    let body = SKSpriteNode(imageNamed: "CoffinBody") // 몸체(내부)
    let lid  = SKSpriteNode(imageNamed: "CoffinLid") // 뚜껑(겉)
    
    private var lidClosedX: CGFloat = 0 // 뚜껑 닫히는 위치 기준
    private var openDistance: CGFloat = 0 // 뚜껑 열릴 때의 이동 거리
    override func didMove(to view: SKView) { //scene이 화면에 뜰 때 spritekit이 자동으로 호출하는 기본 함수라서 override 사용
        backgroundColor = .clear
        view.allowsTransparency = true // SKView 자체도 투명 허용
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // 좌표 기준 = 화면 중앙
        
        // 몸체 (중앙 + 뒤 레이어로)
        body.position = .zero
        body.position = CGPoint(x:30,y:5)
        body.zPosition = 0
        body.size = CGSize(width: 300, height: 1000)
        addChild(body)
        
        // 뚜껑 (몸체와 같은 위치 + 앞 레이어로)
        lid.position = .zero
        body.position = CGPoint(x:0,y:5)
        lid.zPosition = 1
        lidClosedX = lid.position.x // 뚜껑 닫히는 기준인 x(위치) 저장
        openDistance = lid.size.width * 0.5 // 뚜껑 폭만큼 비켜나도록
        addChild(lid)
    }
    
    //진행도(0~1)에 맞춰서 뚜껑을 옆으로 이동할 수 있도록 하는 함수
    func moveLid(progress: Double) { // progress(0~1)
        lid.position.x = lidClosedX + CGFloat(progress) * openDistance // 시작시, 이동 거리를 현재 기준 + 진행도 * 거리로 설정
    }
}
