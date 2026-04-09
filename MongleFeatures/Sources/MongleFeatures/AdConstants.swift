// AdMob 광고 단위 ID - 공개 식별자로 gitignore 불필요
//
// 중요: DEBUG 빌드에서는 반드시 Google 제공 테스트 단위 ID를 사용해야 한다.
// - 운영 단위 ID 를 개발 중에 사용하면 ad fill 이 거의 안 되고 (Google 의 정책)
//   심한 경우 운영 계정이 정책 위반으로 제재를 받을 수 있다.
// - 테스트 ID 는 항상 100% fill 되는 데모 광고를 반환한다.
// 참고: https://developers.google.com/admob/ios/test-ads
enum AdConstants {
    #if os(iOS)
    #if DEBUG
    // Google 공식 테스트 광고 단위 ID (누구나 사용 가능)
    static let bannerAdUnitID   = "ca-app-pub-3940256099942544/2934735716"
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    static let bannerAdUnitID   = "ca-app-pub-4718464707406824/5359748516"
    static let rewardedAdUnitID = "ca-app-pub-4718464707406824/2869316545"
    #endif
    #endif
}
