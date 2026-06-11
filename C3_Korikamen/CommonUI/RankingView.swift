//
//  RankingView.swift
//  C3_Korikamen
//
//  메인 화면에서 여는 랭킹 목록. 이름과 "n분 nn초" 를 빠른 순으로 보여준다.
//

import SwiftUI

struct RankingView: View {
    var onClose: () -> Void
    @StateObject private var store = RankingStore()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()                       // 바닥: fullScreenCover 흰 배경 노출 방지
            Image("bg_start")
                .resizable().scaledToFill().ignoresSafeArea()
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 16) {
                header

                if store.isLoading && store.entries.isEmpty {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if let message = store.errorMessage, store.entries.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text(message).foregroundStyle(.white.opacity(0.9))
                        Button("다시 시도") { Task { await store.load() } }
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                } else if store.entries.isEmpty {
                    Spacer()
                    Text("아직 기록이 없어요.\n첫 기록의 주인공이 되어보세요!")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.entries) { entry in
                                row(entry)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .padding(.top, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)       // 화면 전체를 채워 흰 배경이 비치지 않게
        .task { await store.load() }
    }

    private var header: some View {
        ZStack {
            Text("랭킹")
                .font(Font.custom("NovaMono-Regular", size: 34))
                .foregroundStyle(.white)
            HStack {
                Spacer()
                Button { onClose() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
    }

    private func row(_ entry: ScoreEntry) -> some View {
        HStack(spacing: 16) {
            Text("\(entry.rank)")
                .font(Font.custom("NovaMono-Regular", size: 22))
                .foregroundStyle(rankColor(entry.rank))
                .frame(width: 44, alignment: .center)

            Text(entry.nickname)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Text(RankingFormat.clock(timeMs: entry.timeMs))
                .font(Font.custom("NovaMono-Regular", size: 22))
                .foregroundStyle(.white.opacity(0.95))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1:  return .yellow
        case 2:  return Color(white: 0.8)
        case 3:  return .orange
        default: return .white.opacity(0.8)
        }
    }
}
