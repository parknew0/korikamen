//
//  Stage3_TestView.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/4/26.
//

import SwiftUI
import Combine

struct Stage3_TestView: View {

    var body: some View {
        ZStack{
            Image("Stage3tTimer")
                .resizable()
                .frame(width: 200, height: 70)
        }
            
    }
}

#Preview {
    Stage3_TestView()
}

