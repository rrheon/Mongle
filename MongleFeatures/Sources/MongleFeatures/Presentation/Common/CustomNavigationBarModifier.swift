//
//  SwiftUIView.swift
//  MongleFeatures
//
//  Created by 최용헌 on 3/8/26.
//

import SwiftUI

struct CustomNavigationBarModifier<L, C, R>: ViewModifier where L: View, C: View, R: View {
  let leftView: () -> L
  let centerView: () -> C
  let rightView: () -> R
  let backgroundColor: Color //네비게이션 바 색상
  let borderColor: Color //외곽선 색상
  
  func body(content: Content) -> some View {
    content
      .navigationBarBackButtonHidden(true)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          leftView()
            .padding(.leading, -16)
        }
        ToolbarItem(placement: .principal) {
          centerView()
        }
        ToolbarItem(placement: .topBarTrailing) {
          rightView()
            .padding(.trailing, -16)
        }
      }
      .onAppear{
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backgroundColor = UIColor(backgroundColor)
        navBarAppearance.backgroundEffect = nil
        navBarAppearance.shadowColor = UIColor(borderColor)
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
      }
  }
}
