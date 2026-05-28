//
//  V2AuthGroupScreens.swift
//  Mongle — v2 design handoff
//
//  Screens 12 (Auth login), 13 (Group list), 14 (Create group), 15 (Answer write).
//

import SwiftUI

/// A text-cursor caret that blinks, matching the prototype's CSS blink.
struct V2BlinkingCaret: View {
    var height: CGFloat = 22
    var color: Color = V2Palette.ink
    @State private var visible = true
    var body: some View {
        Rectangle().fill(color).frame(width: 2, height: height)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { visible = false }
            }
    }
}

// MARK: - 12 · Auth Login

struct V2Screen12AuthLogin: View {
    var body: some View {
        let bg = LinearGradient(colors: [Color(hex: "FFF8F0"), Color(hex: "FFE8D6"), Color(hex: "F5DEC8")],
                                startPoint: .top, endPoint: .bottom)
        return V2ScreenContainer(background: bg) {
            // hero — Mongle with angel wings in front
            ZStack {
                V2Mongle(color: V2Palette.alex, size: 80, eyeSize: 14, hideName: true, ringColor: V2Palette.mint)
                V2AngelWings(size: 96).offset(y: 22)
            }
            .frame(width: 120, height: 130)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 180)

            VStack(spacing: 8) {
                Text("몽글").font(V2Font.suit(36, .black)).foregroundStyle(V2Palette.ink)
                Text("오늘의 마음은 어떤 색인가요?").font(V2Font.suit(14, .medium)).foregroundStyle(V2Palette.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 340)

            VStack(spacing: 10) {
                authButton(bg: Color(hex: "FFE500"), border: false) {
                    Image(systemName: "bubble.left.fill").font(.system(size: 16)).foregroundStyle(V2Palette.ink)
                    Text("카카오톡으로 계속하기").font(V2Font.suit(15, .bold)).foregroundStyle(V2Palette.ink)
                }
                authButton(bg: .white, border: true) {
                    Image("GoogleLogin", bundle: .module).resizable().scaledToFit().frame(width: 18, height: 18)
                    Text("Google로 계속하기").font(V2Font.suit(15, .semibold)).foregroundStyle(V2Palette.ink)
                }
                authButton(bg: .white, border: true) {
                    Image(systemName: "applelogo").font(.system(size: 18)).foregroundStyle(V2Palette.ink)
                    Text("Apple로 계속하기").font(V2Font.suit(15, .semibold)).foregroundStyle(V2Palette.ink)
                }
                authButton(bg: .white, border: true) {
                    Image(systemName: "envelope.fill").font(.system(size: 16)).foregroundStyle(V2Palette.ink)
                    Text("이메일로 계속하기").font(V2Font.suit(15, .semibold)).foregroundStyle(V2Palette.ink)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 464)

            Text("둘러보기").font(V2Font.suit(13, .semibold)).foregroundStyle(V2Palette.muted)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 740)
        }
    }

    private func authButton<C: View>(bg: Color, border: Bool, @ViewBuilder content: () -> C) -> some View {
        HStack(spacing: 8) { content() }
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                if border {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(V2Palette.hairline, lineWidth: 1)
                }
            }
            .shadow(color: border ? .clear : .black.opacity(0.12), radius: 6, y: 4)
    }
}

// MARK: - 13 · Group List

struct V2Screen13GroupList: View {
    private struct GroupItem: Identifiable {
        let id = UUID()
        var name: String; var members: Int; var status: String; var avatars: [Color]; var primary: Bool
    }
    private let groups = [
        GroupItem(name: "박씨네", members: 5, status: "오늘 3명 답변", avatars: V2Palette.family, primary: true),
        GroupItem(name: "동기들", members: 4, status: "어제 4명 답변", avatars: [V2Palette.mom, V2Palette.alex, V2Palette.lily, V2Palette.ben], primary: false),
    ]

    var body: some View {
        V2ScreenContainer(background: V2Palette.cream) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("몽글").font(V2Font.suit(26, .black)).foregroundStyle(V2Palette.ink)
                        Spacer()
                        Image(systemName: "bell.fill").font(.system(size: 20)).foregroundStyle(V2Palette.ink)
                            .frame(width: 36, height: 36).background(.white, in: Circle())
                            .overlay(alignment: .topTrailing) {
                                Circle().fill(V2Palette.notif).frame(width: 8, height: 8)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: 1.5)).offset(x: -6, y: 6)
                            }
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                    Text("내 그룹 · 2개").font(V2Font.suit(13, .semibold)).foregroundStyle(V2Palette.muted)

                    ForEach(groups) { g in groupCard(g) }

                    // create CTA
                    HStack(spacing: 8) {
                        Image(systemName: "plus").font(.system(size: 22)).foregroundStyle(V2Palette.mutedSoft)
                        Text("새 그룹 만들기").font(V2Font.suit(15, .bold)).foregroundStyle(V2Palette.mutedSoft)
                    }
                    .frame(maxWidth: .infinity).padding(20)
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6])).foregroundStyle(V2Palette.muted))

                    // invite chip
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill").font(.system(size: 24)).foregroundStyle(V2Palette.heartPink)
                            .frame(width: 44, height: 44).background(Color(hex: "FFEBEE"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("초대 1건이 도착했어요").font(V2Font.suit(14, .heavy)).foregroundStyle(V2Palette.ink)
                            Text("김씨네 가족 · 어제").font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.muted)
                        }
                        Spacer()
                        Text("수락").font(V2Font.suit(12, .heavy)).foregroundStyle(V2Palette.ink)
                            .padding(.horizontal, 14).padding(.vertical, 8).background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(16).background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                }
                .padding(.horizontal, 16).padding(.top, 62).padding(.bottom, 30)
            }
        }
    }

    private func groupCard(_ g: GroupItem) -> some View {
        HStack(spacing: 16) {
            ZStack(alignment: .topLeading) {
                ForEach(Array(g.avatars.prefix(4).enumerated()), id: \.offset) { j, c in
                    Circle().fill(c).frame(width: 36, height: 36)
                        .overlay(Circle().strokeBorder(g.primary ? V2Palette.ink : .white, lineWidth: 2))
                        .offset(x: CGFloat(j % 2) * 28 + (j > 1 ? 8 : 0), y: CGFloat(j / 2) * 28)
                }
            }
            .frame(width: 80, height: 64, alignment: .topLeading)
            VStack(alignment: .leading, spacing: 4) {
                Text(g.name).font(V2Font.suit(17, .heavy)).foregroundStyle(g.primary ? .white : V2Palette.ink)
                Text("\(g.members)명 · \(g.status)").font(V2Font.suit(12, .regular))
                    .foregroundStyle(g.primary ? Color.white.opacity(0.65) : V2Palette.muted)
                if g.primary {
                    HStack(spacing: 4) {
                        Circle().fill(V2Palette.ink).frame(width: 6, height: 6)
                        Text("오늘의 질문 진행중").font(V2Font.suit(11, .bold)).foregroundStyle(V2Palette.ink)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 4).background(V2Palette.mint, in: Capsule()).padding(.top, 4)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 20))
                .foregroundStyle(g.primary ? Color.white.opacity(0.5) : V2Palette.muted)
        }
        .padding(18).background(g.primary ? V2Palette.ink : .white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

// MARK: - 14 · Create Group

struct V2Screen14CreateGroup: View {
    private let icons: [(Color, String, Bool)] = [
        (V2Palette.heartPink, "house.fill", true),
        (V2Palette.mom, "person.3.fill", false),
        (V2Palette.lily, "pawprint.fill", false),
        (V2Palette.ben, "graduationcap.fill", false),
        (V2Palette.alex, "birthday.cake.fill", false),
        (V2Palette.coral, "star.fill", false),
    ]

    var body: some View {
        V2ScreenContainer(background: V2Palette.cream) {
            // top bar
            HStack {
                Image(systemName: "xmark").font(.system(size: 22, weight: .semibold)).foregroundStyle(V2Palette.ink)
                Spacer()
                Text("새 그룹").font(V2Font.suit(17, .heavy)).foregroundStyle(V2Palette.ink)
                Spacer()
                Text("건너뛰기").font(V2Font.suit(14, .bold)).foregroundStyle(V2Palette.muted)
            }
            .padding(.horizontal, 20).frame(height: 56)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 56)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Capsule().fill(V2Palette.mint).frame(height: 4)
                    Capsule().fill(V2Palette.mint).frame(height: 4)
                    Capsule().fill(Color(hex: "E5DDD0")).frame(height: 4)
                }
                Text("2/3 단계").font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.coral).tracking(0.3).padding(.top, 12)
                Text("어떤 가족인가요?").font(V2Font.suit(24, .black)).foregroundStyle(V2Palette.ink).padding(.top, 6)

                // field
                Text("그룹 이름").font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.muted).padding(.top, 28)
                HStack(spacing: 2) {
                    Text("박씨네").font(V2Font.suit(16, .bold)).foregroundStyle(V2Palette.ink)
                    V2BlinkingCaret(height: 22)
                    Spacer()
                }
                .padding(.horizontal, 16).frame(height: 56)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(V2Palette.mint, lineWidth: 1.5))
                .padding(.top, 8)
                Text("4~12자 · 가족 모두에게 보여요").font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.muted).padding(.top, 6)

                // icon selector
                Text("그룹 아이콘").font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.muted).padding(.top, 24)
                HStack(spacing: 10) {
                    ForEach(Array(icons.enumerated()), id: \.offset) { _, it in
                        Image(systemName: it.1).font(.system(size: 26)).foregroundStyle(V2Palette.ink)
                            .frame(width: 56, height: 56)
                            .background(it.0, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(it.2 ? V2Palette.ink : .clear, lineWidth: 2.5))
                    }
                }
                .padding(.top, 10)

                // preview
                HStack(spacing: 14) {
                    Image(systemName: "house.fill").font(.system(size: 28)).foregroundStyle(V2Palette.ink)
                        .frame(width: 56, height: 56).background(V2Palette.heartPink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("미리보기").font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.muted)
                        Text("박씨네").font(V2Font.suit(17, .heavy)).foregroundStyle(V2Palette.ink)
                    }
                    Spacer()
                }
                .padding(18).background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous)).padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 126)

            // bottom buttons
            HStack(spacing: 10) {
                Text("이전").font(V2Font.suit(15, .bold)).foregroundStyle(V2Palette.mutedSoft)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Color(hex: "F1ECE3"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text("다음").font(V2Font.suit(15, .heavy)).foregroundStyle(V2Palette.ink)
                    .frame(maxWidth: .infinity).frame(height: 54).layoutPriority(1)
                    .background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom).padding(.bottom, 50)
        }
    }
}

// MARK: - 15 · Answer Write

struct V2Screen15AnswerWrite: View {
    private let text = "처음 자전거를 혼자 타고 외할머니 댁까지 갔던 날. 어른이 된 기분이었어."

    var body: some View {
        V2ScreenContainer(background: Color(hex: "FFF8F0")) {
            // top bar
            HStack {
                Image(systemName: "xmark").font(.system(size: 22)).foregroundStyle(V2Palette.ink)
                    .frame(width: 36, height: 36).background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill").font(.system(size: 14)).foregroundStyle(V2Palette.heartPink)
                    Text("+2 하트").font(V2Font.suit(12, .heavy)).foregroundStyle(V2Palette.ink)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .padding(.horizontal, 16).frame(height: 56)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 56)

            VStack(spacing: 16) {
                // question card
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Circle().fill(V2Palette.coral).frame(width: 6, height: 6)
                        Text("오늘의 질문 · 4월 15일").font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.coral).tracking(0.3)
                    }
                    Text("엄마가 제일 행복했던 순간은?").font(V2Font.suit(20, .heavy)).foregroundStyle(V2Palette.ink).padding(.top, 8)
                    Text("엄마가 가족에게 물어봤어요").font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.muted).padding(.top, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                // textarea
                VStack(alignment: .leading, spacing: 0) {
                    (Text(text).font(V2Font.suit(15, .regular)).foregroundStyle(V2Palette.ink))
                        .lineSpacing(6).frame(maxWidth: .infinity, alignment: .leading)
                    Rectangle().fill(Color(hex: "F3EBE0")).frame(height: 1).padding(.top, 18)
                    HStack {
                        HStack(spacing: 14) {
                            Image(systemName: "camera").foregroundStyle(V2Palette.mutedSoft)
                            Image(systemName: "face.smiling").foregroundStyle(V2Palette.mutedSoft)
                            Image(systemName: "mic").foregroundStyle(V2Palette.mutedSoft)
                        }.font(.system(size: 22))
                        Spacer()
                        Text("\(text.count)/300").font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.muted)
                    }.padding(.top, 12)
                }
                .padding(18).frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                // visibility chip
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill").font(.system(size: 16)).foregroundStyle(V2Palette.mintInk)
                    Text("박씨네 가족 5명에게만 공개").font(V2Font.suit(13, .bold)).foregroundStyle(V2Palette.ink)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(V2Palette.mint.opacity(0.25), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 124)

            // submit
            HStack(spacing: 8) {
                Text("답변 보내기").font(V2Font.suit(16, .heavy)).foregroundStyle(V2Palette.ink)
                Image(systemName: "paperplane.fill").font(.system(size: 16)).foregroundStyle(V2Palette.ink)
            }
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom).padding(.bottom, 50)
        }
    }
}

#Preview("12 · Auth") { V2Screen12AuthLogin() }
#Preview("13 · Group List") { V2Screen13GroupList() }
#Preview("14 · Create Group") { V2Screen14CreateGroup() }
#Preview("15 · Answer Write") { V2Screen15AnswerWrite() }
