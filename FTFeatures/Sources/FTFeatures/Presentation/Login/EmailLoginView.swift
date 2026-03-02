//
//  EmailLoginView.swift
//  Mongle
//
//  Created by 최용헌 on 12/13/25.
//

import SwiftUI

struct EmailLoginView: View {
  var body: some View {
    VStack(spacing: 20) {
      FTTextField(
        title: "이메일",
        placeholder: "example@email.com",
        text: .constant(""),
        keyboardType: .emailAddress
      )
      
      FTTextField(
        title: "비밀번호",
        placeholder: "최소 6자 이상",
        text: .constant(""),
        isSecure: true
      )
      
      FTButton("로그인", style: .primary) {}

    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }
}

#Preview {
  EmailLoginView()
}
