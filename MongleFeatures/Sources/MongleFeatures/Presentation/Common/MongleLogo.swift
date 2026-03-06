//
//  MongleLogo.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI

struct MongleLogo: View {
  enum MongleLogoType: String {
    case MongleIcon
    case MongleImg
  }
  
  enum Size {
    case small
    case medium
    case large
    
    var dimension: CGFloat {
      switch self {
      case .small: return 48
      case .medium: return 80
      case .large: return 160
      }
    }
  }
  
  let size: Size
  let logo: MongleLogoType
  
  init(size: Size = .medium, type: MongleLogoType = .MongleIcon) {
    self.size = size
    self.logo = type
  }
  
  var body: some View {
    Image(logo.rawValue)
      .resizable()
      .scaledToFill()
      .frame(width: size.dimension, height: size.dimension)
      .foregroundColor(MongleColor.primary)
  }
}

#Preview {
  VStack(spacing: 20) {
    MongleLogo(size: .small)
    MongleLogo(size: .medium)
    MongleLogo(size: .large)
  }
  
  VStack(spacing: 20) {
    MongleLogo(size: .small, type: .MongleImg)
    MongleLogo(size: .medium, type: .MongleImg)
    MongleLogo(size: .large, type: .MongleImg)
      .foregroundStyle(Color.blue)
  }
}
