//
//  StoryView.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/5/26.
//  스토리 화면 셸(재사용). 현재 컷 1개를 레이어로 조립해 그리고 탭을 처리.

import Foundation
import SwiftUI

struct StoryView: View {
    @StateObject var player: StoryPlayer //player의 index/beat가 바뀌면 화면 갱신되도록
    @State private var coverOpacity: Double = 0   // 전환막 투명도 서서히 걷혀 어두웠다가 화면이 드러날 때 사용
    var body: some View {
        let page = player.pages[player.index] //지금 그릴 컷
        
        ZStack {
            
            //배경 전환 애니메이션 추가
            if case .fade(let color,_) = page.transition {
                color
                    .opacity(coverOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            //1. 배경(없으면 검은 화면이 보이도록)
            if let bg = page.background {
                Image(bg).resizable().scaledToFill()
            } else {
                Color.black
            }
            
            //2. 연출 이미지들
            ForEach(page.overlays) { overlay in
                Image(overlay.image)
                    .resizable()
                    .scaledToFit()
            }
            
            //3. 텍스트 패널
            if let panel = page.panel {
                VStack{
                    Spacer()
                    ZStack{
                        Image(panel.image).resizable().scaledToFit().offset(x: 0, y: 80).frame(width: 1100,height: 400)
                        
                        HStack{
                            TypewriterText(fullText: panel.text, beat: player.beat, onFinished: {player.settle() }) // 천천히 나오도록 추가
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)   // 세로로 늘어나게
                                .multilineTextAlignment(.leading)        // 왼쪽 정렬
                                .font(Font.system(size: 28))
                                .foregroundStyle(Color.brown)
                                .padding(.top, 24)
                                .padding(.leading, 100)
                            Spacer()
                        }
                        
                    }
                    .padding(.bottom, 40)
                
                   
                }
            }
            
            if player.beat == .settled {
                HStack {
                    Spacer()
                    Spacer()
                    VStack(alignment:.trailing){
                        Spacer()
                        Image("nextarrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                    }
                    .padding(.bottom, 200)
                    .padding(.trailing, 100)
                    
                }
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle()) //빈 곳도 탭 인식
        .onTapGesture {
            player.tap() // 화면 아무데나 탭 하면 텍스트나 이미지 스킵(바로 나오도록)
        }
        .onAppear { // id(player.index) 와 함께, 컷 뜰 때 막 걷기
            if case .fade(_, let duration) = page.transition {
                coverOpacity = 1
                withAnimation(.easeInOut(duration: duration)) {
                    coverOpacity = 0
                }
            }
        }
        .id(player.index) //컷 바뀌면 리마운트 다음 컷이 나오도록 -> 연출 리셋
       
    }
}
