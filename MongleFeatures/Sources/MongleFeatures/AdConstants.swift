// AdMob 광고 단위 ID - 공개 식별자로 gitignore 불필요
enum AdConstants {
    #if os(iOS)
    static let bannerAdUnitID   = "ca-app-pub-4718464707406824/5359748516"
    static let rewardedAdUnitID = "ca-app-pub-4718464707406824/2869316545"
    #endif
}
