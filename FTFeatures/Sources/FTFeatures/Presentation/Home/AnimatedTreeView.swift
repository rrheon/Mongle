//
//  AnimatedTreeView.swift
//  Mongle
//
//  Created by 최용헌 on 12/14/25.
//

import SwiftUI
import Domain

struct AnimatedTreeView: View {
    let stage: TreeStage
    let size: CGFloat
    
    @State private var isAnimating = false
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(FTColor.primaryLight.opacity(0.3))
                .frame(width: size, height: size)
            
            animatedTreeImage
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Tree Image by Stage
    private var treeImage: Image {
        switch stage {
        case .seed:
            return Image(systemName: "circle.fill")
        case .sprout:
            return Image(systemName: "leaf")
        case .sapling:
            return Image(systemName: "leaf.fill")
        case .youngTree:
            return Image(systemName: "tree")
        case .matureTree:
            return Image(systemName: "tree.fill")
        case .flowering:
            return Image(systemName: "sparkles")
  
        case .bound:
          return Image(systemName: "circle.fill")

        }
    }
    
    // MARK: - Animated Tree Image
    @ViewBuilder
    private var animatedTreeImage: some View {
        let baseImage = treeImage
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.5, height: size * 0.5)
            .foregroundColor(FTColor.primary)
        
        switch stage {
        case .seed:
            // 씨앗: 땅속에서 살짝 움직이는 느낌 (발아 준비)
            baseImage
                .scaleEffect(scale)
                .offset(y: yOffset)
        
        case .sprout:
            // 새싹: 땅을 뚫고 나와 위로 자라는 느낌
            baseImage
                .scaleEffect(scale)
                .offset(y: yOffset)
                .opacity(opacity)
        
        case .sapling:
            // 작은 나무: 바람에 가볍게 흔들리는 어린 나무
            baseImage
                .rotationEffect(.degrees(rotation), anchor: .bottom)
                .offset(x: xOffset)
        
        case .youngTree:
            // 청년 나무: 잎이 바람에 살랑살랑 흔들림
            baseImage
                .rotationEffect(.degrees(rotation), anchor: .bottom)
                .scaleEffect(x: 1.0 + (xOffset * 0.01), y: 1.0)
        
        case .matureTree:
            // 큰 나무: 묵직하게 천천히 흔들림 (안정감)
            baseImage
                .rotationEffect(.degrees(rotation), anchor: .bottom)
                .offset(x: xOffset * 0.5)
        
        case .flowering:
            // 꽃 피는 나무: 꽃이 반짝이며 피는 느낌
            baseImage
                .scaleEffect(scale)
                .opacity(opacity)
                .rotationEffect(.degrees(rotation), anchor: .center)
        case .bound:
          baseImage
              .scaleEffect(scale)
              .offset(y: yOffset)
        }
    }
    
    // MARK: - Start Animation
    private func startAnimation() {
        switch stage {
        case .bound:
            // 통통 튀는 애니메이션
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
            ) {
                yOffset = -10
            }
            
        case .seed:
            // 씨앗: 땅속에서 살짝 움직이며 숨쉬는 느낌
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                scale = 1.05
            }
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                yOffset = 2
            }
            
        case .sprout:
            // 새싹: 땅을 뚫고 나오며 위로 자라는 애니메이션
            withAnimation(
                .spring(response: 2.0, dampingFraction: 0.6)
                .repeatForever(autoreverses: true)
            ) {
                scale = 1.1
                yOffset = -3
            }
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                opacity = 0.85
            }
            
        case .sapling:
            // 작은 나무: 바람에 가볍게 좌우로 흔들림
            animateSwaying(amplitude: 8, duration: 2.0, rotationAmount: 6)
            
        case .youngTree:
            // 청년 나무: 잎이 바람에 살랑살랑 흔들림 (중간 강도)
            animateSwaying(amplitude: 5, duration: 2.5, rotationAmount: 4)
            
        case .matureTree:
            // 큰 나무: 묵직하게 천천히 흔들림
            animateSwaying(amplitude: 3, duration: 3.5, rotationAmount: 2)
            
        case .flowering:
            // 꽃 피는 나무: 꽃이 피고 반짝이는 효과
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                scale = 1.15
            }
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                opacity = 0.8
            }
            withAnimation(
                .linear(duration: 8.0)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
    
    // MARK: - Helper: Swaying Animation
    /// 나무가 바람에 흔들리는 애니메이션
    /// - Parameters:
    ///   - amplitude: 좌우 움직임의 크기
    ///   - duration: 애니메이션 지속 시간
    ///   - rotationAmount: 회전 각도
    private func animateSwaying(amplitude: CGFloat, duration: Double, rotationAmount: Double) {
        // 좌우 흔들림
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
            xOffset = amplitude
        }
        
        // 회전 (나무 밑동을 기준으로)
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
            rotation = rotationAmount
        }
        
        // 약간의 딜레이를 주어 더 자연스러운 흔들림
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) {
            withAnimation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
            ) {
                xOffset = -amplitude
                rotation = -rotationAmount
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            VStack {
                AnimatedTreeView(stage: .seed, size: 80)
                Text("씨앗")
                    .font(.caption)
            }
            
            VStack {
                AnimatedTreeView(stage: .sprout, size: 80)
                Text("새싹")
                    .font(.caption)
            }
            
            VStack {
                AnimatedTreeView(stage: .sapling, size: 80)
                Text("작은 나무")
                    .font(.caption)
            }
        }
        
        HStack(spacing: 20) {
            VStack {
                AnimatedTreeView(stage: .youngTree, size: 80)
                Text("청년 나무")
                    .font(.caption)
            }
            
            VStack {
                AnimatedTreeView(stage: .matureTree, size: 80)
                Text("큰 나무")
                    .font(.caption)
            }
            
            VStack {
                AnimatedTreeView(stage: .flowering, size: 80)
                Text("꽃 피는 나무")
                    .font(.caption)
            }
        }
    }
    .padding()
}
