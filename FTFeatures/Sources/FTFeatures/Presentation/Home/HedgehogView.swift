//
//  HedgehogView.swift
//  Mongle
//
//  Created by Claude on 1/7/26.
//

import SwiftUI
import Domain

// MARK: - 가족 멤버 고슴도치 데이터
struct HedgehogMember: Identifiable, Equatable {
    let id: UUID
    let user: User
    var hasAnswered: Bool
    var position: CGPoint
    var targetPosition: CGPoint
    var direction: HedgehogDirection
    var isResting: Bool = false  // 쉬는 중인지 여부

    enum HedgehogDirection {
        case left, right
    }
}

// MARK: - 단일 고슴도치 뷰 (답변 상태 + 이름표 포함)
struct HedgehogCharacterView: View {
    let member: HedgehogMember
    let size: CGFloat
    let hasActiveQuestion: Bool

    @State private var bounceOffset: CGFloat = 0
    @State private var squashScale: CGFloat = 1.0
    @State private var tiltAngle: Double = 0

    var body: some View {
        VStack(spacing: 2) {
            // 답변 상태 표시 (질문이 있을 때만)
            if hasActiveQuestion {
                AnswerStatusBadge(hasAnswered: member.hasAnswered)
                    .transition(.scale.combined(with: .opacity))
            }

            // 고슴도치 본체
            HedgehogBody(
                size: size,
                direction: member.direction,
                isWalking: !member.isResting
            )
            .scaleEffect(x: 1.0, y: squashScale, anchor: .bottom)
            .rotationEffect(.degrees(tiltAngle))
            .offset(y: bounceOffset)

            // 이름표
            NameTag(name: member.user.name)
        }
        .onChange(of: member.isResting) { _, isResting in
            if isResting {
                stopWalkingAnimation()
            } else {
                startWalkingAnimation()
            }
        }
        .onAppear {
            if !member.isResting {
                startWalkingAnimation()
            }
        }
    }

    private func startWalkingAnimation() {
        // 통통 튀는 애니메이션
        withAnimation(
            .easeInOut(duration: 0.2)
            .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -6
        }

        // 찌그러지는 효과 (착지할 때 눌리는 느낌)
        withAnimation(
            .easeInOut(duration: 0.2)
            .repeatForever(autoreverses: true)
        ) {
            squashScale = 0.9
        }

        // 좌우로 살짝 기울어지는 효과
        withAnimation(
            .easeInOut(duration: 0.25)
            .repeatForever(autoreverses: true)
        ) {
            tiltAngle = 3
        }
    }

    private func stopWalkingAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            bounceOffset = 0
            squashScale = 1.0
            tiltAngle = 0
        }
    }
}

// MARK: - 답변 상태 뱃지
struct AnswerStatusBadge: View {
    let hasAnswered: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(hasAnswered ? FTColor.success : FTColor.surface)
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            Image(systemName: hasAnswered ? "checkmark" : "questionmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(hasAnswered ? .white : FTColor.textHint)
        }
    }
}

// MARK: - 이름표
struct NameTag: View {
    let name: String

    var body: some View {
        Text(name)
            .font(FTFont.caption())
            .foregroundColor(FTColor.textPrimary)
            .padding(.horizontal, FTSpacing.xs)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(FTColor.cardBackground)
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            )
    }
}

// MARK: - 고슴도치 본체 (이미지 사용)
struct HedgehogBody: View {
    let size: CGFloat
    let direction: HedgehogMember.HedgehogDirection
    let isWalking: Bool

    // 회전 각도 (누적 방식으로 랜덤 회전 방향 지원)
    @State private var rotationAngle: Double = 0
    @State private var currentDirection: HedgehogMember.HedgehogDirection?

    var body: some View {
        Image("hedgehog_character", bundle: Bundle.module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .rotation3DEffect(
                .degrees(rotationAngle),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.3
            )
            .onAppear {
                currentDirection = direction
                rotationAngle = direction == .left ? 180 : 0
            }
            .onChange(of: direction) { _, newDirection in
                guard currentDirection != newDirection else { return }
                currentDirection = newDirection

                // 랜덤하게 시계방향(+180) 또는 반시계방향(-180) 선택
                let rotationDelta: Double = Bool.random() ? 180 : -180

                withAnimation(.easeInOut(duration: 0.3)) {
                    rotationAngle += rotationDelta
                }
            }
    }
}

// MARK: - 고슴도치 정원 (여러 고슴도치가 돌아다니는 영역)
struct HedgehogGardenView: View {
    let members: [User]
    let memberAnswerStatus: [UUID: Bool]  // userId: hasAnswered
    let hasActiveQuestion: Bool
    let gardenSize: CGSize

    @State private var hedgehogs: [HedgehogMember] = []
    @State private var animationTimer: Timer?
    @State private var overlapTimers: [UUID: TimeInterval] = [:]  // 겹침 시간 추적
    @State private var restTimers: [UUID: TimeInterval] = [:]  // 휴식 시간 추적

    // 이동 설정
    private let stepSize: CGFloat = 3  // 한 걸음 크기 (느리게)
    private let movementInterval: TimeInterval = 0.15  // 이동 간격 (초)
    private let targetReachedThreshold: CGFloat = 15  // 목표 도달 판정 거리
    private let collisionRadius: CGFloat = 50  // 충돌 감지 반경
    private let overlapTimeLimit: TimeInterval = 5.0  // 겹침 허용 시간 (초)
    private let wallPadding: CGFloat = 50  // 벽 여백
    private let restChance: Double = 0.02  // 매 프레임 쉬기 시작할 확률 (2%)
    private let minRestDuration: TimeInterval = 2.0  // 최소 휴식 시간
    private let maxRestDuration: TimeInterval = 5.0  // 최대 휴식 시간

    var body: some View {
        ZStack {
            // 배경 (잔디)
            GardenBackground()

            // 고슴도치들
            ForEach(hedgehogs) { hedgehog in
                HedgehogCharacterView(
                    member: hedgehog,
                    size: hedgehogSize,
                    hasActiveQuestion: hasActiveQuestion
                )
                .position(hedgehog.position)
                .animation(.linear(duration: movementInterval), value: hedgehog.position)
            }
        }
        .frame(width: gardenSize.width, height: gardenSize.height)
        .clipShape(RoundedRectangle(cornerRadius: FTRadius.xl))
        .onAppear {
            initializeHedgehogs()
            startMovementTimer()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
        .onChange(of: members) { _, newMembers in
            updateHedgehogs(with: newMembers)
        }
        .onChange(of: memberAnswerStatus) { _, newStatus in
            updateAnswerStatus(with: newStatus)
        }
    }

    private var hedgehogSize: CGFloat {
        // 멤버 수에 따라 크기 조절
        let baseSize: CGFloat = 60
        let memberCount = members.count
        if memberCount <= 2 { return baseSize }
        if memberCount <= 4 { return baseSize * 0.85 }
        return baseSize * 0.7
    }

    private func initializeHedgehogs() {
        hedgehogs = members.enumerated().map { index, user in
            let position = randomPosition()
            let target = randomPosition()
            return HedgehogMember(
                id: user.id,
                user: user,
                hasAnswered: memberAnswerStatus[user.id] ?? false,
                position: position,
                targetPosition: target,
                direction: target.x > position.x ? .right : .left
            )
        }
    }

    private func updateHedgehogs(with newMembers: [User]) {
        let existingIds = Set(hedgehogs.map { $0.id })
        let newIds = Set(newMembers.map { $0.id })

        // 새로 추가된 멤버
        for user in newMembers where !existingIds.contains(user.id) {
            let position = randomPosition()
            let target = randomPosition()
            let newHedgehog = HedgehogMember(
                id: user.id,
                user: user,
                hasAnswered: memberAnswerStatus[user.id] ?? false,
                position: position,
                targetPosition: target,
                direction: target.x > position.x ? .right : .left
            )
            hedgehogs.append(newHedgehog)
        }

        // 삭제된 멤버 제거
        hedgehogs.removeAll { !newIds.contains($0.id) }
    }

    private func updateAnswerStatus(with newStatus: [UUID: Bool]) {
        for index in hedgehogs.indices {
            if let hasAnswered = newStatus[hedgehogs[index].id] {
                hedgehogs[index].hasAnswered = hasAnswered
            }
        }
    }

    private func randomPosition() -> CGPoint {
        let x = CGFloat.random(in: wallPadding...(gardenSize.width - wallPadding))
        let y = CGFloat.random(in: wallPadding...(gardenSize.height - wallPadding))
        return CGPoint(x: x, y: y)
    }

    private func startMovementTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: movementInterval, repeats: true) { _ in
            stepTowardsTarget()
        }
    }

    private func stepTowardsTarget() {
        for index in hedgehogs.indices {
            let hedgehogId = hedgehogs[index].id

            // 쉬는 중인지 체크
            if hedgehogs[index].isResting {
                // 휴식 시간 감소
                let remainingRest = (restTimers[hedgehogId] ?? 0) - movementInterval
                if remainingRest <= 0 {
                    // 휴식 끝
                    hedgehogs[index].isResting = false
                    restTimers[hedgehogId] = 0
                } else {
                    restTimers[hedgehogId] = remainingRest
                }
                continue
            }

            // 랜덤하게 쉬기 시작 (쉬는 인원 1명 제한)
            let restingCount = hedgehogs.filter { $0.isResting }.count
            if restingCount == 0 && Double.random(in: 0...1) < restChance {
                hedgehogs[index].isResting = true
                restTimers[hedgehogId] = TimeInterval.random(in: minRestDuration...maxRestDuration)
                continue
            }

            let current = hedgehogs[index].position
            let target = hedgehogs[index].targetPosition

            // 목표까지의 거리 계산
            let dx = target.x - current.x
            let dy = target.y - current.y
            let distance = sqrt(dx * dx + dy * dy)

            // 목표에 도달했으면 새로운 목표 설정
            if distance < targetReachedThreshold {
                if Bool.random() {
                    let newTarget = randomPosition()
                    hedgehogs[index].targetPosition = newTarget
                    hedgehogs[index].direction = newTarget.x > current.x ? .right : .left
                }
                continue
            }

            // 목표 방향으로 한 걸음 이동
            let stepX = (dx / distance) * stepSize
            let stepY = (dy / distance) * stepSize

            var newPosition = CGPoint(
                x: current.x + stepX,
                y: current.y + stepY
            )

            // 벽 충돌 체크 - 벽에 닿으면 즉시 새 목표 설정
            let hitWall = checkAndHandleWallCollision(index: index, position: &newPosition)
            if hitWall {
                let newTarget = randomPosition()
                hedgehogs[index].targetPosition = newTarget
                hedgehogs[index].direction = newTarget.x > current.x ? .right : .left
            }

            // 다른 고슴도치와 겹침 체크
            let isOverlapping = checkOverlapWithOthers(index: index, at: newPosition)
            if isOverlapping {
                // 겹침 시간 누적
                let currentOverlapTime = overlapTimers[hedgehogId] ?? 0
                overlapTimers[hedgehogId] = currentOverlapTime + movementInterval

                // 5초 이상 겹치면 새 목표 설정
                if overlapTimers[hedgehogId]! >= overlapTimeLimit {
                    let newTarget = randomPosition()
                    hedgehogs[index].targetPosition = newTarget
                    hedgehogs[index].direction = newTarget.x > current.x ? .right : .left
                    overlapTimers[hedgehogId] = 0
                }
            } else {
                // 겹치지 않으면 타이머 초기화
                overlapTimers[hedgehogId] = 0
            }

            // 방향 업데이트 (좌우만)
            if abs(stepX) > 0.1 {
                hedgehogs[index].direction = stepX > 0 ? .right : .left
            }

            hedgehogs[index].position = newPosition
        }
    }

    // 벽 충돌 체크 및 위치 보정 (벽에 닿으면 true 반환)
    private func checkAndHandleWallCollision(index: Int, position: inout CGPoint) -> Bool {
        var hitWall = false

        if position.x <= wallPadding {
            position.x = wallPadding
            hitWall = true
        } else if position.x >= gardenSize.width - wallPadding {
            position.x = gardenSize.width - wallPadding
            hitWall = true
        }

        if position.y <= wallPadding {
            position.y = wallPadding
            hitWall = true
        } else if position.y >= gardenSize.height - wallPadding {
            position.y = gardenSize.height - wallPadding
            hitWall = true
        }

        return hitWall
    }

    // 다른 고슴도치와 겹침 여부 확인
    private func checkOverlapWithOthers(index: Int, at position: CGPoint) -> Bool {
        for otherIndex in hedgehogs.indices where otherIndex != index {
            let otherPosition = hedgehogs[otherIndex].position
            let dx = position.x - otherPosition.x
            let dy = position.y - otherPosition.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < collisionRadius {
                return true
            }
        }
        return false
    }
}

// MARK: - 정원 배경
struct GardenBackground: View {
    var body: some View {
        ZStack {
            // 잔디 배경
            LinearGradient(
                colors: [
                    Color(hex: "90EE90").opacity(0.3),
                    Color(hex: "7CCD7C").opacity(0.4)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // 잔디 패턴
            GeometryReader { geometry in
                ForEach(0..<20, id: \.self) { _ in
                    GrassBlade()
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
    }
}

struct GrassBlade: View {
    @State private var sway: CGFloat = 0

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addQuadCurve(
                to: CGPoint(x: 2, y: 0),
                control: CGPoint(x: -3 + sway, y: 10)
            )
            path.addQuadCurve(
                to: CGPoint(x: 4, y: 20),
                control: CGPoint(x: 7 + sway, y: 10)
            )
        }
        .fill(Color(hex: "228B22").opacity(0.5))
        .frame(width: 8, height: 20)
        .onAppear {
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.5...2.5))
                .repeatForever(autoreverses: true)
            ) {
                sway = CGFloat.random(in: -2...2)
            }
        }
    }
}

// MARK: - Preview
#Preview("Hedgehog Garden") {
    VStack {
        HedgehogGardenView(
            members: [
                User(id: UUID(), email: "dad@test.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                User(id: UUID(), email: "mom@test.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                User(id: UUID(), email: "son@test.com", name: "아들", profileImageURL: nil, role: .son, createdAt: .now),
                User(id: UUID(), email: "daughter@test.com", name: "딸", profileImageURL: nil, role: .daughter, createdAt: .now)
            ],
            memberAnswerStatus: [:],
            hasActiveQuestion: true,
            gardenSize: CGSize(width: 350, height: 280)
        )
    }
    .padding()
    .background(FTColor.background)
}

#Preview("Single Hedgehog") {
    HedgehogCharacterView(
        member: HedgehogMember(
            id: UUID(),
            user: User(id: UUID(), email: "test@test.com", name: "테스트", profileImageURL: nil, role: .son, createdAt: .now),
            hasAnswered: false,
            position: .zero,
            targetPosition: .zero,
            direction: .right
        ),
        size: 80,
        hasActiveQuestion: true
    )
    .padding()
}
