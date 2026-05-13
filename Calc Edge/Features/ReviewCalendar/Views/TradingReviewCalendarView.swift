import SwiftData
import SwiftUI

struct TradingReviewCalendarView: View {
    @Query(sort: \Trade.openedAt, order: .reverse) private var trades: [Trade]

    @State private var visibleMonth = Date.now
    @State private var selectedDay: ReviewCalendarDaySummary?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var days: [ReviewCalendarDaySummary] {
        ReviewCalendarSummaryBuilder.monthDays(containing: visibleMonth, trades: trades)
    }

    private var selectedSummary: ReviewCalendarDaySummary {
        selectedDay ?? days.first(where: { !$0.trades.isEmpty }) ?? ReviewCalendarDaySummary(date: Date.now, trades: [])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                calendarGrid
                selectedDaySection
            }
            .padding()
        }
        .navigationTitle("Review Calendar")
        .onAppear {
            selectedDay = days.first(where: { calendar.isDate($0.date, inSameDayAs: Date.now) })
        }
        .onChange(of: visibleMonth) { _, _ in
            selectedDay = days.first(where: { !$0.trades.isEmpty })
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .help("Previous Month")

            VStack(alignment: .leading, spacing: 2) {
                Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Daily trading results, review coverage, and process notes.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Today") {
                visibleMonth = Date.now
                selectedDay = days.first(where: { calendar.isDate($0.date, inSameDayAs: Date.now) })
            }
            .buttonStyle(.bordered)

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
            .help("Next Month")
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(calendar.shortStandaloneWeekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(days) { day in
                ReviewCalendarDayCell(
                    summary: day,
                    isInVisibleMonth: calendar.isDate(day.date, equalTo: visibleMonth, toGranularity: .month),
                    isSelected: selectedDay?.id == day.id
                ) {
                    selectedDay = day
                }
            }
        }
    }

    private var selectedDaySection: some View {
        let summary = selectedSummary

        return InfoSection(title: summary.date.formatted(.dateTime.weekday(.wide).day().month(.wide))) {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], alignment: .leading, spacing: 12) {
                    InfoStatCard(title: "Trades", value: "\(summary.tradeCount)")
                    InfoStatCard(
                        title: "Expectancy",
                        value: JournalInsightsFormatting.rMultiple(summary.expectancy),
                        accentColor: JournalInsightsFormatting.valueColor(for: summary.expectancy)
                    )
                    InfoStatCard(title: "Review Coverage", value: JournalInsightsFormatting.percent(summary.reviewCoverage))
                    InfoStatCard(title: "Followed Plan", value: JournalInsightsFormatting.percent(summary.followedPlanRate))
                }

                if let topMistake = summary.topMistake {
                    InfoRow(title: "Top Mistake", detail: topMistake)
                }

                if summary.trades.isEmpty {
                    Text("No trades logged for this day.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(summary.trades.sorted { $0.openedAt > $1.openedAt }) { trade in
                        NavigationLink {
                            TradeJournalDetailView(trade: trade)
                        } label: {
                            TradeJournalRow(trade: trade)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func moveMonth(by value: Int) {
        if let nextMonth = calendar.date(byAdding: .month, value: value, to: visibleMonth) {
            visibleMonth = nextMonth
        }
    }
}

private struct ReviewCalendarDayCell: View {
    let summary: ReviewCalendarDaySummary
    let isInVisibleMonth: Bool
    let isSelected: Bool
    let action: () -> Void

    private var accentColor: Color {
        guard let expectancy = summary.expectancy else {
            return .secondary
        }

        return expectancy >= 0 ? .green : .red
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(summary.date.formatted(.dateTime.day()))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    if summary.tradeCount > 0 {
                        Text("\(summary.tradeCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }
                }

                Spacer(minLength: 8)

                if summary.tradeCount > 0 {
                    Text(JournalInsightsFormatting.rMultiple(summary.expectancy))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(accentColor)

                    ProgressView(value: summary.reviewCoverage ?? 0, total: 1)
                        .progressViewStyle(.linear)
                        .tint(accentColor)
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                }
            }
            .padding(10)
            .frame(minHeight: 92, maxHeight: 110)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? .regularMaterial : .thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? accentColor : .clear, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(isInVisibleMonth ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isInVisibleMonth && summary.tradeCount == 0)
    }
}
