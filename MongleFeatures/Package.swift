// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MongleFeatures",
    defaultLocalization: "ko",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MongleFeatures",
            targets: ["MongleFeatures"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../MongleData"),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.9.0"
        ),
        // KakaoSDK: Xcode에서 패키지 추가 후 package 파라미터 이름을 확인하세요.
        // 보통 "kakao-ios-sdk" 또는 "KakaoOpenSDK" 입니다.
        .package(
            url: "https://github.com/kakao/kakao-ios-sdk",
            from: "2.22.0"
        ),
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS",
            from: "7.0.0"
        ),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads",
            from: "11.0.0"
        ),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform",
            from: "2.1.0"
        ),
    ],
    targets: [
        .target(
            name: "MongleFeatures",
            dependencies: [
                "Domain",
                "MongleData",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                .product(name: "KakaoSDKCommon", package: "kakao-ios-sdk"),
                .product(name: "KakaoSDKAuth",   package: "kakao-ios-sdk"),
                .product(name: "KakaoSDKUser",   package: "kakao-ios-sdk"),
                .product(name: "GoogleSignIn",   package: "GoogleSignIn-iOS"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-user-messaging-platform"),
            ],
            path: "Sources/MongleFeatures",
            resources: [
                .process("Assets.xcassets"),
                .process("Fonts"),
                .process("Resources")
            ],
            // SPM 패키지는 메인 앱 타겟의 SWIFT_ACTIVE_COMPILATION_CONDITIONS 를 상속하지
            // 않아서, 명시 정의가 없으면 #if DEBUG 가 항상 false 로 컴파일된다. 그 결과
            // Root+Reducer 의 deviceTokenReceived 가 DEBUG 빌드에서도 environment="production"
            // 으로 등록 → BadDeviceToken → 서버 자동 invalidate → 푸시 미수신 무한 루프.
            // .when(configuration: .debug) 가드로 Debug 에서만 매크로 정의. (MG-114)
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "MongleFeaturesTests",
            dependencies: [
                "MongleFeatures",
                "Domain",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Tests/MongleFeaturesTests"
        ),
    ]
)
