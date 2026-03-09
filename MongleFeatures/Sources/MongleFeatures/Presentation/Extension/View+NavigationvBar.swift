//
//  SwiftUIView.swift
//  MongleFeatures
//
//  Created by 최용헌 on 3/8/26.
//

import SwiftUI

extension View {
  func customNavigationBar<L: View, C: View, R: View>(
      leftView: @escaping () -> L = { EmptyView() },
      centerView: @escaping () -> C = { EmptyView() },
      rightView: @escaping () -> R = { EmptyView() },
      backgroundColor: Color = MongleColor.background,
      borderColor: Color = MongleColor.border
  ) -> some View {
      self.modifier(CustomNavigationBarModifier(
          leftView: leftView,
          centerView: centerView,
          rightView: rightView,
          backgroundColor: backgroundColor,
          borderColor: borderColor
      ))
  }
}
