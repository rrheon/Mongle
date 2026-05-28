//
//  V2NotifScreens.swift
//  Mongle — v2 design handoff
//
//  Screens 16 (알림 inbox) and 17 (알림 설정). 17 reuses V2SectionGroup/V2SettingRow.
//

import SwiftUI

// MARK: - Notification item

struct V2NotifItem: View {
    var avatar: Color
    var who: String
    var what: String
    var time: String
    var unread: Bool = false
    var action: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(avatar).frame(width: 42, height: 42)
                .overlay(Circle().strokeBorder(V2Palette.inkSoft, lineWidth: 1.5))
                .overlay {
                    HStack(spacing: 4) {
                        eye; eye
                    }.offset(y: 2)
                }
            VStack(alignment: .leading, spacing: 4) {
                (Text(who).font(V2Font.suit(13, .heavy)) + Text(" " + what).font(V2Font.suit(13, .regular)))
                    .foregroundStyle(V2Palette.ink).lineSpacing(2)
                Text(time).font(V2Font.suit(11, .regular)).foregroundStyle(V2Palette.muted)
            }
            Spacer(minLength: 0)
            if let action {
                Text(action).font(V2Font.suit(11, .heavy)).foregroundStyle(V2Palette.ink)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else if unread {
                Circle().fill(V2Palette.notif).frame(width: 8, height: 8).padding(.top, 6)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(unread ? AnyShapeStyle(V2Palette.mint.opacity(0.18)) : AnyShapeStyle(Color.white),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: unread ? .clear : .black.opacity(0.04), radius: 6, y: 1)
    }

    private var eye: some View {
        Circle().fill(V2Palette.ink).frame(width: 6, height: 6).overlay(Circle().strokeBorder(.white, lineWidth: 1))
    }
}

// MARK: - 16 · Notifications

struct V2Screen16Notifications: View {
    var body: some View {
        V2ScreenContainer(background: V2Palette.cream) {
            // fixed header + tabs
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "chevron.left").font(.system(size: 22)).foregroundStyle(V2Palette.ink)
                    Spacer()
                    Text("알림").font(V2Font.suit(17, .heavy)).foregroundStyle(V2Palette.ink)
                    Spacer()
                    Image(systemName: "gearshape.fill").font(.system(size: 20)).foregroundStyle(V2Palette.ink)
                }
                .padding(.horizontal, 20).frame(height: 56)

                HStack(spacing: 8) {
                    tabPill("전체", count: 8, active: true)
                    tabPill("가족", count: 4, active: false)
                    tabPill("시스템", count: 2, active: false)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 12)
            }
            .padding(.top, 56).background(V2Palette.cream)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .zIndex(1)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("오늘")
                    V2NotifItem(avatar: V2Palette.mom, who: "엄마", what: "가 오늘의 질문에 답변했어요", time: "방금", unread: true)
                    V2NotifItem(avatar: V2Palette.dad, who: "아빠", what: "가 배경을 '들판'으로 바꿨어요", time: "2시간 전", unread: true)
                    V2NotifItem(avatar: V2Palette.lily, who: "릴리", what: "가 화관을 선물했어요 🌸", time: "오전 10:24", action: "확인")

                    sectionLabel("어제").padding(.top, 8)
                    V2NotifItem(avatar: V2Palette.ben, who: "벤", what: "이 답변을 깜빡했어요. 살짝 찔러볼까요?", time: "어제 21:00", action: "찌르기")
                    V2NotifItem(avatar: Color(hex: "FFEBEE"), who: "시스템", what: "12일 연속 답변 달성! +5 하트", time: "어제 09:00")

                    sectionLabel("이번 주").padding(.top, 8)
                    V2NotifItem(avatar: Color(hex: "FFF3E0"), who: "기념일", what: "엄마 생신이 3일 남았어요", time: "4월 12일")
                }
                .padding(.horizontal, 16).padding(.bottom, 30)
            }
            .padding(.top, 170)
        }
    }

    private func tabPill(_ title: String, count: Int, active: Bool) -> some View {
        HStack(spacing: 6) {
            Text(title).font(V2Font.suit(13, .bold)).foregroundStyle(active ? .white : V2Palette.muted)
            Text("\(count)").font(V2Font.suit(11, .heavy)).foregroundStyle(active ? V2Palette.mint : V2Palette.muted)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(active ? AnyShapeStyle(V2Palette.ink) : AnyShapeStyle(Color.white), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: active ? .clear : .black.opacity(0.04), radius: 6, y: 1)
    }

    private func sectionLabel(_ t: String) -> some View {
        Text(t).font(V2Font.suit(11, .bold)).tracking(0.4).foregroundStyle(V2Palette.muted)
            .padding(.leading, 4)
    }
}

// MARK: - 17 · Notification Settings

struct V2Screen17NotificationSettings: View {
    var body: some View {
        V2ScreenContainer(background: V2Palette.cream) {
            // top bar
            HStack {
                Image(systemName: "chevron.left").font(.system(size: 22)).foregroundStyle(V2Palette.ink)
                Spacer()
                Text("알림 설정").font(V2Font.suit(17, .heavy)).foregroundStyle(V2Palette.ink)
                Spacer()
                Image(systemName: "chevron.left").font(.system(size: 22)).foregroundStyle(.clear)
            }
            .padding(.horizontal, 20).frame(height: 56)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 56)

            VStack(spacing: 16) {
                // hero card
                VStack(alignment: .leading, spacing: 0) {
                    Text("오늘의 질문").font(V2Font.suit(11, .bold)).tracking(0.4).foregroundStyle(V2Palette.mint)
                    Text("매일 9:00 AM").font(V2Font.suit(22, .heavy)).foregroundStyle(.white).padding(.top, 6)
                    Text("가족에게 새 질문이 도착해요").font(V2Font.suit(12, .regular)).foregroundStyle(.white.opacity(0.6)).padding(.top, 6)
                    HStack(spacing: 6) {
                        ForEach(Array(["7AM","9AM","10AM","12PM","저녁 8시"].enumerated()), id: \.offset) { i, t in
                            Text(t).font(V2Font.suit(11, .heavy))
                                .foregroundStyle(i == 1 ? V2Palette.ink : Color.white.opacity(0.8))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(i == 1 ? AnyShapeStyle(V2Palette.mint) : AnyShapeStyle(Color.white.opacity(0.10)),
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }.padding(.top, 14)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18).background(V2Palette.ink, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        V2SectionGroup(title: "질문 알림") {
                            V2SettingRow(icon: "clock", label: "알림 시간", value: "아침 9시")
                            V2SettingRow(icon: "sofa.fill", label: "주말 알림", toggle: true)
                            V2SettingRow(icon: "moon.zzz.fill", label: "방해 금지", value: "22:00–08:00", isLast: true)
                        }
                        V2SectionGroup(title: "가족 활동") {
                            V2SettingRow(icon: "arrowshape.turn.up.left.fill", label: "가족 답변 알림", toggle: true)
                            V2SettingRow(icon: "photo", label: "배경/꾸미기 변경", toggle: false)
                            V2SettingRow(icon: "gift.fill", label: "기념일 리마인더", toggle: true, isLast: true)
                        }
                        V2SectionGroup(title: "알림 표시") {
                            V2SettingRow(icon: "speaker.wave.2.fill", label: "알림음", value: "물방울")
                            V2SettingRow(icon: "iphone.radiowaves.left.and.right", label: "진동", toggle: true, isLast: true)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 116).padding(.bottom, 30)
        }
    }
}

#Preview("16 · Notifications") { V2Screen16Notifications() }
#Preview("17 · Notification Settings") { V2Screen17NotificationSettings() }
