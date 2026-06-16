//
//  MongleLogo.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI

struct MongleLogo: View {
  enum MongleLogoType: String {
    case MongleLogo
    case MongleIcon
  }
  
  enum Size {
    case small
    case medium
    case large
    
    var dimension: CGFloat {
      switch self {
      case .small: return 36
      case .medium: return 60
      case .large: return 116
      }
    }
  }
  
  let size: Size
  let logo: MongleLogoType
  
  init(size: Size = .medium, type: MongleLogoType = .MongleLogo) {
    self.size = size
    self.logo = type
  }
  
  var body: some View {
    switch logo {
    case .MongleLogo:
      // 홈 화면 캐릭터(V2Mongle)와 형태/눈/섀도를 일치시킨 로고용 몽글. 본체는 홈 민트 계열을
      // 연하게 한 톤으로 두어 눈의 흰 테두리가 또렷하게 살게 하고, 홈 캐릭터에는 없는
      // 볼터치(cheek blush)만 더해 로그인·로딩·온보딩·그룹·검색 등의 로고를 통일.
      MongleLogoMonggle(size: size.dimension)
    case .MongleIcon:
      Image(logo.rawValue, bundle: .module)
        .renderingMode(.original)
        .resizable()
        .scaledToFill()
        .frame(width: size.dimension, height: size.dimension)
    }
  }
}

/// 로고 전용 몽글 캐릭터.
/// 홈 화면 캐릭터(`V2Mongle`)의 본체/눈 형태·위치·드롭섀도를 그대로 복제하되,
/// 본체는 홈 민트(mom)를 연하게 한 톤으로 두어 흰 눈테가 살게 하고, 홈 캐릭터에는 없는 볼터치(cheek blush)를 추가한다.
/// (V2Mongle 은 이름표/뱃지/장식 슬롯 등 가족 화면용 컨테이너를 포함해 로고로 쓰기엔
///  여백/정렬이 맞지 않으므로, 동일한 형태를 size×size 로 깔끔히 재현한 별도 뷰로 둔다.)
private struct MongleLogoMonggle: View {
  var size: CGFloat
  // 본체 색 — 홈 캐릭터의 민트(calm mood = V2Palette.mom #A8DFBC)를 흰색 쪽으로 살짝 밝힌
  // 연한 민트. 크림(거의 흰색)이면 눈의 흰 테두리가 묻혀 안 보이므로 유채색 본체를 쓰되,
  // 톤은 홈 민트 계열로 맞추고 한 단계 연하게.
  var color: Color = Color(hex: "C6E9D2")

  private var eye: CGFloat { size * 0.18 }

  var body: some View {
    ZStack {
      // 본체 — 홈 캐릭터와 동일: 솔리드 원 + inkSoft 얇은 테두리 + 드롭섀도.
      Circle()
        .fill(color)
        .overlay(Circle().strokeBorder(V2Palette.inkSoft, lineWidth: 1.5))
        .shadow(color: Color.black.opacity(0.32), radius: size * 0.1, x: 0, y: size * 0.057)
        .frame(width: size, height: size)

      // 볼터치 — 눈 아래 바깥쪽 소프트 핑크 타원. (홈 캐릭터에 없던 추가 요소)
      cheek.offset(x: -size * 0.27, y: size * 0.17)
      cheek.offset(x:  size * 0.27, y: size * 0.17)

      // 눈 — 홈 캐릭터(V2Mongle)와 동일 위치/스타일: 흰 테두리 + ink 동공, ±0.15·size / +0.03·size.
      eyeView.offset(x: -size * 0.15, y: size * 0.03)
      eyeView.offset(x:  size * 0.15, y: size * 0.03)
    }
    .frame(width: size, height: size)
  }

  private var eyeView: some View {
    Circle()
      .fill(V2Palette.ink)
      .frame(width: eye, height: eye)
      .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
  }

  private var cheek: some View {
    Ellipse()
      .fill(V2Palette.heartPink.opacity(0.5))
      .frame(width: size * 0.20, height: size * 0.12)
      .blur(radius: size * 0.012)
  }
}

#Preview {
  VStack(spacing: 20) {
    MongleLogo(size: .small)
    MongleLogo(size: .medium)
    MongleLogo(size: .large)
  }
  
  VStack(spacing: 20) {
    MongleLogo(size: .small, type: .MongleIcon)
    MongleLogo(size: .medium, type: .MongleLogo)
    MongleLogo(size: .large, type: .MongleLogo)
  }
}
