// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MongleFeatures",
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
            ],
            path: "Sources/MongleFeatures",
            resources: [.process("Assets.xcassets")]
        ),
    ]
)
