//
//  V2HistorySettingsScreens.swift
//  Mongle — v2 design handoff
//
//  Screens 09 (히스토리 calendar), 10 (MY/Settings light), 11 (알림 설정 dark).
//  Also defines the shared settings row + section group reused by 16/17.
//

import SwiftUI

private let v2Family: [Color] = [V2Palette.dad, V2Palette.mom, V2Palette.lily, V2Palette.ben, V2Palette.alex]

// MARK: - Shared settings primitives

struct V2SettingRow: View {
    var icon: String
    var label: String
    var value: String? = nil
    var rightIcon: String = "chevron.right"
    var toggle: Bool? = nil
    var dark: Bool = false
    var isLast: Bool = false

    private var ink: Color { dark ? .white : V2Palette.ink }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 18))
                    .foregroundStyle(dark ? .white : V2Palette.mutedSoft)
                    .frame(width: 32, height: 32)
                    .background(dark ? Color.white.opacity(0.08) : Color(hex: "F7F0E5"),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(label).font(V2Font.suit(14, .semibold)).foregroundStyle(ink)
                Spacer()
                if let value {
                    Text(value).font(V2Font.suit(13, .regular))
                        .foregroundStyle(dark ? Color.white.opacity(0.5) : V2Palette.muted)
                }
                if let toggle {
                    V2Toggle(isOn: toggle, dark: dark)
                } else {
                    Image(systemName: rightIcon).font(.system(size: 16))
                        .foregroundStyle(dark ? Color.white.opacity(0.4) : V2Palette.muted)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            if !isLast {
                Rectangle().fill(dark ? Color.white.opacity(0.06) : Color(hex: "F3EBE0")).frame(height: 1)
            }
        }
    }
}

struct V2Toggle: View {
    var isOn: Bool
    var dark: Bool = false
    var body: some View {
        Capsule()
            .fill(isOn ? V2Palette.mint : (dark ? Color(hex: "3A3A3A") : Color(hex: "E5DDD0")))
            .frame(width: 40, height: 24)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle().fill(.white).frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                    .padding(2)
            }
    }
}

struct V2SectionGroup<Content: View>: View {
    var title: String
    var dark: Bool = false
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(V2Font.suit(12, .bold)).tracking(0.4)
                .foregroundStyle(dark ? Color.white.opacity(0.5) : V2Palette.muted)
                .padding(.horizontal, 16)
            VStack(spacing: 0) { content() }
                .background(dark ? Color.white.opacity(0.04) : .white,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - 09 · History

struct V2Screen09History: View {
    private struct Day: Identifiable { let id = UUID(); var n: Int; var dots: [Color] = []; var dim = false; var today = false }
    private let weeks: [[Day]] = [
        [Day(n: 29, dim: true), Day(n: 30, dim: true), Day(n: 31, dim: true),
         Day(n: 1, dots: [V2Palette.dad, V2Palette.mom, V2Palette.alex]),
         Day(n: 2, dots: v2Family),
         Day(n: 3, dots: [V2Palette.mom, V2Palette.alex]),
         Day(n: 4, dots: [V2Palette.dad, V2Palette.mom, V2Palette.lily, V2Palette.alex])],
        [Day(n: 5, dots: v2Family), Day(n: 6, dots: [V2Palette.mom, V2Palette.alex]),
         Day(n: 7, dots: [V2Palette.dad, V2Palette.mom, V2Palette.alex]),
         Day(n: 8, dots: [V2Palette.dad, V2Palette.mom, V2Palette.lily, V2Palette.alex]),
         Day(n: 9, dots: [V2Palette.mom, V2Palette.lily, V2Palette.alex]),
         Day(n: 10, dots: v2Family), Day(n: 11, dots: [V2Palette.mom, V2Palette.alex])],
        [Day(n: 12, dots: [V2Palette.dad, V2Palette.mom, V2Palette.alex]),
         Day(n: 13, dots: [V2Palette.mom, V2Palette.alex]),
         Day(n: 14, dots: [V2Palette.dad, V2Palette.mom, V2Palette.lily, V2Palette.alex]),
         Day(n: 15, dots: v2Family, today: true),
         Day(n: 16), Day(n: 17), Day(n: 18)],
        [Day(n: 19), Day(n: 20), Day(n: 21), Day(n: 22), Day(n: 23), Day(n: 24), Day(n: 25)],
    ]

    var body: some View {
        V2ScreenContainer(background: V2Palette.cream) {
            // header
            HStack {
                Text("히스토리").font(V2Font.suit(18, .heavy)).foregroundStyle(V2Palette.ink)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold))
                    Text("2026년 4월").font(V2Font.suit(13, .bold))
                    Image(systemName: "chevron.right").font(.system(size: 18, weight: .bold))
                }.foregroundStyle(V2Palette.ink)
            }
            .padding(.horizontal, 20).frame(height: 56)
            .frame(maxWidth: .infinity).background(.white)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 56)

            // weekday + grid
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(Array(["일","월","화","수","목","금","토"].enumerated()), id: \.offset) { i, d in
                        Text(d).font(V2Font.suit(12, .bold))
                            .foregroundStyle(i == 0 ? V2Palette.notif : (i == 6 ? V2Palette.blueSat : V2Palette.ink))
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(Array(week.enumerated()), id: \.element.id) { i, day in
                            calCell(day, weekdayIndex: i)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 124)

            // today summary card
            todayCard
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 440).padding(.horizontal, 16)

            // streak chip
            streakChip
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 560).padding(.horizontal, 16)

            V2BottomNav(active: .history)
        }
    }

    private func calCell(_ day: V2Screen09History.Day, weekdayIndex i: Int) -> some View {
        var color = V2Palette.ink
        if i == 0 { color = V2Palette.notif }
        if i == 6 { color = V2Palette.blueSat }
        if day.dim { color = Color(hex: "CFC4B8") }
        return VStack(spacing: 4) {
            Text("\(day.n)").font(V2Font.suit(14, day.today ? .heavy : .regular))
                .foregroundStyle(day.today ? V2Palette.ink : color)
                .frame(width: 28, height: 28)
                .background(day.today ? V2Palette.mint : .clear, in: Circle())
            HStack(spacing: 2) {
                ForEach(Array(day.dots.enumerated()), id: \.offset) { _, c in
                    Circle().fill(c).frame(width: 4, height: 4)
                }
            }.frame(height: 4)
        }
        .frame(maxWidth: .infinity).frame(height: 44)
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("4월 15일 · 오늘").font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.coral).tracking(0.3)
                    Text("엄마가 제일 행복했던 순간은?").font(V2Font.suit(17, .heavy)).foregroundStyle(V2Palette.ink)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 20)).foregroundStyle(V2Palette.muted)
            }
            HStack(spacing: 8) {
                ForEach(Array(v2Family.enumerated()), id: \.offset) { _, c in
                    Circle().fill(c).frame(width: 32, height: 32)
                        .overlay(Circle().strokeBorder(V2Palette.inkSoft, lineWidth: 1.5))
                        .overlay(alignment: .bottomTrailing) {
                            ZStack {
                                Circle().fill(V2Palette.mint).overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                                Image(systemName: "checkmark").font(.system(size: 7, weight: .black)).foregroundStyle(V2Palette.ink)
                            }.frame(width: 12, height: 12).offset(x: 2, y: 2)
                        }
                }
            }.padding(.top, 14)
        }
        .padding(18).background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var streakChip: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame.fill").font(.system(size: 26)).foregroundStyle(V2Palette.streak)
                .frame(width: 44, height: 44)
                .background(Color(hex: "FFF3E0"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("12일 연속 답변").font(V2Font.suit(15, .heavy)).foregroundStyle(V2Palette.ink)
                Text("이번 달 가족 답변률 89%").font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 18)).foregroundStyle(V2Palette.muted)
        }
        .padding(18).frame(height: 64)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

// MARK: - 10 · MY / Settings (light)

struct V2Screen10Settings: View {
    var body: some View {
        V2ScreenContainer(background: V2Palette.cream) {
            navBar(title: "MY", dark: false)

            VStack(spacing: 16) {
                // profile card
                HStack(spacing: 14) {
                    V2Mongle(color: V2Palette.alex, size: 60, eyeSize: 12, hideName: true) { V2FlowerCrown(small: true) }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("알렉스").font(V2Font.suit(17, .heavy)).foregroundStyle(V2Palette.ink)
                        Text("박씨네 · 12일 연속").font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.muted)
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill").font(.system(size: 12)).foregroundStyle(V2Palette.heartPink)
                            Text("5 하트").font(V2Font.suit(11, .heavy)).foregroundStyle(V2Palette.ink)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color(hex: "FFEBEE"), in: Capsule()).padding(.top, 4)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 20)).foregroundStyle(V2Palette.muted)
                }
                .padding(18).background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        V2SectionGroup(title: "가족") {
                            V2SettingRow(icon: "person.2.fill", label: "가족 그룹 관리", value: "박씨네")
                            V2SettingRow(icon: "person.badge.plus", label: "가족 초대")
                            V2SettingRow(icon: "party.popper.fill", label: "기념일", value: "3개", isLast: true)
                        }
                        V2SectionGroup(title: "알림") {
                            V2SettingRow(icon: "bell.fill", label: "푸시 알림", toggle: true)
                            V2SettingRow(icon: "clock", label: "알림 시간", value: "아침 9시")
                            V2SettingRow(icon: "megaphone.fill", label: "가족 활동 알림", toggle: true, isLast: true)
                        }
                        V2SectionGroup(title: "앱") {
                            V2SettingRow(icon: "moon.fill", label: "다크모드", value: "자동")
                            V2SettingRow(icon: "lock.fill", label: "개인정보 처리방침")
                            V2SettingRow(icon: "info.circle", label: "버전 정보", value: "2.0.1", isLast: true)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 116).padding(.bottom, 30)
        }
    }
}

// MARK: - 11 · 알림 설정 (dark)

struct V2Screen11SettingsDark: View {
    var body: some View {
        V2ScreenContainer(background: V2Palette.dark) {
            navBar(title: "알림 설정", dark: true)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("오늘의 질문").font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.coral).tracking(0.3)
                    Text("매일 9:00 AM").font(V2Font.suit(18, .heavy)).foregroundStyle(.white).padding(.top, 6)
                    Text("가족에게 새 질문이 도착해요").font(V2Font.suit(12, .regular)).foregroundStyle(.white.opacity(0.6)).padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        V2SectionGroup(title: "질문 알림", dark: true) {
                            V2SettingRow(icon: "clock", label: "알림 시간", value: "아침 9시", dark: true)
                            V2SettingRow(icon: "sofa.fill", label: "주말 알림", toggle: true, dark: true)
                            V2SettingRow(icon: "moon.zzz.fill", label: "방해 금지 시간", value: "22:00–08:00", dark: true, isLast: true)
                        }
                        V2SectionGroup(title: "가족 활동", dark: true) {
                            V2SettingRow(icon: "arrowshape.turn.up.left.fill", label: "가족 답변 알림", toggle: true, dark: true)
                            V2SettingRow(icon: "photo", label: "배경/꾸미기 변경", toggle: false, dark: true)
                            V2SettingRow(icon: "gift.fill", label: "기념일 리마인더", toggle: true, dark: true, isLast: true)
                        }
                        V2SectionGroup(title: "기타", dark: true) {
                            V2SettingRow(icon: "speaker.wave.2.fill", label: "알림음", value: "물방울", dark: true)
                            V2SettingRow(icon: "iphone.radiowaves.left.and.right", label: "진동", toggle: true, dark: true, isLast: true)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 116).padding(.bottom, 30)
        }
    }
}

// MARK: - Shared nav bar (back / title / spacer)

@ViewBuilder
private func navBar(title: String, dark: Bool) -> some View {
    let ink: Color = dark ? .white : V2Palette.ink
    HStack {
        Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(ink)
        Spacer()
        Text(title).font(V2Font.suit(17, .heavy)).foregroundStyle(ink)
        Spacer()
        Image(systemName: "chevron.left").font(.system(size: 22)).foregroundStyle(.clear)
    }
    .padding(.horizontal, 20).frame(height: 56)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 56)
}

#Preview("09 · 히스토리") { V2Screen09History() }
#Preview("10 · MY/Settings") { V2Screen10Settings() }
#Preview("11 · 알림 설정 (Dark)") { V2Screen11SettingsDark() }
