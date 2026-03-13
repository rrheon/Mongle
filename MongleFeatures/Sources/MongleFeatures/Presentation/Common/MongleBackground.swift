import SwiftUI

/// 몽글 앱 공통 배경 그라디언트
/// Onboarding, Home 등 주요 화면에서 공유되는 따뜻한 그라디언트 배경
struct MongleBackground: View {
    var body: some View {
        LinearGradient(
            colors: [MongleColor.gradientBgStart, MongleColor.gradientBgMid, MongleColor.gradientBgEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

extension View {
    /// 몽글 공통 배경 그라디언트를 ZStack 없이 간편하게 적용
    func mongleBackground() -> some View {
        ZStack {
            MongleBackground()
            self
        }
    }
}

#Preview {
    MongleBackground()
}
