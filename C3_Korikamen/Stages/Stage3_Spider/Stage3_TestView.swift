//
//  Stage3_TestView.swift
//  C3_Korikamen
//
//  Created by 이환훈 on 6/4/26.
//

import SwiftUI

struct Stage3_TestView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        Image(systemName: "arrow.forward")
            .symbolEffect(.wiggle.byLayer, options: .repeat(.periodic(delay: 0.4)))
            .font(.system(size: 50)) // 원하는 크기 지정
            .foregroundColor(Color.white)
    }
}

#Preview {
    Stage3_TestView()
}
