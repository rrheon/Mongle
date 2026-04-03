import SwiftUI

// MARK: - MongleNavigationHeader

/// 공통 네비게이션 헤더
/// 기본 구조: 왼쪽버튼 | 가운데 타이틀 | 오른쪽버튼
/// - left, right에 원하는 뷰를 넣어 커스텀 가능
/// - 버튼이 없는 쪽은 EmptyView() 전달
public struct MongleNavigationHeader<Left: View, Right: View>: View {
  private let title: String
  private let leftContent: Left
  private let rightContent: Right
  
  public init(
    title: String = "",
    @ViewBuilder left: () -> Left,
    @ViewBuilder right: () -> Right
  ) {
    self.title = title
    self.leftContent = left()
    self.rightContent = right()
  }
  
  public var body: some View {
    ZStack {
      // 타이틀: 좌우 버튼 크기와 무관하게 정중앙 배치
      if !title.isEmpty {
        Text(title)
          .font(MongleFont.heading3())
          .foregroundColor(MongleColor.textPrimary)
          .lineLimit(1)
      }

      // 좌우 버튼
      HStack(spacing: 0) {
        leftContent
        Spacer(minLength: 0)
        rightContent
      }
    }
    .frame(height: 56)
    .padding(.horizontal, MongleSpacing.xs)
    .background(Color.white)
  }
}

// MARK: - MongleBackButton

/// 공통 뒤로가기 버튼 (MongleNavigationHeader left에 사용)
public struct MongleBackButton: View {
  private let action: () -> Void
  
  public init(action: @escaping () -> Void) {
    self.action = action
  }
  
  public var body: some View {
    Button(action: action) {
      Image(systemName: "chevron.left")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(MongleColor.textPrimary)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(MongleScaleButtonStyle())
  }
}
