//
//  FTLogo.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI

struct FTLogo: View {
  enum FTLogoType: String {
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
  let logo: FTLogoType
  
  init(size: Size = .medium, type: FTLogoType = .MongleIcon) {
    self.size = size
    self.logo = type
  }
  
  var body: some View {
    Image(logo.rawValue)
      .resizable()
      .scaledToFill()
      .frame(width: size.dimension, height: size.dimension)
      .foregroundColor(FTColor.primary)
  }
}

#Preview {
  VStack(spacing: 20) {
    FTLogo(size: .small)
    FTLogo(size: .medium)
    FTLogo(size: .large)
  }
  
  VStack(spacing: 20) {
    FTLogo(size: .small, type: .MongleImg)
    FTLogo(size: .medium, type: .MongleImg)
    FTLogo(size: .large, type: .MongleImg)
      .foregroundStyle(Color.blue)
  }
}
