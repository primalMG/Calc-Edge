import SwiftData
import SwiftUI

struct TradingReviewCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trade.openedAt, order: .reverse) private var trades: [Trade]

    @State private var visibleMonth = Date.now
    @State private var calendarMode: ReviewCalendarDateMode = .reviewDate
    @State private var selectedDay: ReviewCalendarDaySummary?
    @State private var toast: ToastConfiguration?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    #if DEBUG
    private let mockCalendarAccount = "Review Calendar Demo"
    #endif

    private var days: [ReviewCalendarDaySummary] {
        ReviewCalendarSummaryBuilder.monthDays(containing: visibleMonth, trades: trades, mode: calendarMode)
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
        .onChange(of: calendarMode) { _, _ in
            selectedDay = days.first(where: { calendar.isDate($0.date, inSameDayAs: selectedSummary.date) })
                ?? days.first(where: { !$0.trades.isEmpty })
        }
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        seedMockCalendarData()
                    } label: {
                        Label("Seed Mock Data", systemImage: "calendar.badge.plus")
                    }

                    Button(role: .destructive) {
                        clearMockCalendarData()
                    } label: {
                        Label("Clear Mock Data", systemImage: "trash")
                    }
                } label: {
                    Label("Mock Data", systemImage: "shippingbox")
                }
                .help("Mock Data")
            }
            #endif
        }
        .toast($toast)
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

            Picker("Calendar Mode", selection: $calendarMode) {
                ForEach(ReviewCalendarDateMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 260)
            .help("Calendar Mode")

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
                    InfoStatCard(title: "Open", value: "\(summary.openTradeCount)")
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
                    Text(emptyMessage)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(summary.trades.sorted { calendarDate(for: $0) > calendarDate(for: $1) }) { trade in
                        NavigationLink {
                            TradeJournalDetailView(trade: trade)
                        } label: {
                            ReviewCalendarTradeRow(trade: trade)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
            }
        }
    }

    private var emptyMessage: String {
        switch calendarMode {
        case .reviewDate:
            return "No trades to review for this day."
        case .openedDate:
            return "No trades opened on this day."
        }
    }

    private func moveMonth(by value: Int) {
        if let nextMonth = calendar.date(byAdding: .month, value: value, to: visibleMonth) {
            visibleMonth = nextMonth
        }
    }

    private func calendarDate(for trade: Trade) -> Date {
        ReviewCalendarSummaryBuilder.calendarDate(for: trade, mode: calendarMode)
    }

    #if DEBUG
    private func seedMockCalendarData() {
        let removedCount = deleteMockCalendarTrades()
        let mockTrades = ReviewCalendarMockDataFactory.trades(for: visibleMonth)

        for trade in mockTrades {
            modelContext.insert(trade)

            if let review = trade.review {
                modelContext.insert(review)
            }

            if let context = trade.context {
                modelContext.insert(context)
            }
        }

        do {
            try modelContext.save()
            selectedDay = nil
            toast = ToastConfiguration(
                title: "Mock Data Ready",
                message: "Added \(mockTrades.count) calendar trades\(removedCount > 0 ? " after replacing \(removedCount)" : "").",
                state: .success
            )
        } catch {
            toast = ToastConfiguration(
                title: "Mock Seed Failed",
                message: error.localizedDescription,
                state: .error,
                duration: 4
            )
        }
    }

    private func clearMockCalendarData() {
        let removedCount = deleteMockCalendarTrades()

        do {
            try modelContext.save()
            selectedDay = nil
            toast = ToastConfiguration(
                title: "Mock Data Cleared",
                message: "\(removedCount) demo trades removed.",
                state: .info
            )
        } catch {
            toast = ToastConfiguration(
                title: "Clear Failed",
                message: error.localizedDescription,
                state: .error,
                duration: 4
            )
        }
    }

    @discardableResult
    private func deleteMockCalendarTrades() -> Int {
        let mockTrades = trades.filter { $0.account == mockCalendarAccount }

        for trade in mockTrades {
            modelContext.delete(trade)
        }

        return mockTrades.count
    }
    #endif
}

#if DEBUG
private enum ReviewCalendarMockDataFactory {
    private static let mockAccount = "Review Calendar Demo"

    static func trades(for month: Date) -> [Trade] {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: month)?.start ?? month

        let fixtures: [Fixture] = [
            Fixture(openDay: 1, closeDay: 1, ticker: "AAPL", direction: .long, setup: "Opening Drive", entry: 194, exit: 199, stop: 192, target: 200, reviewed: true, followedPlan: true, mistake: nil, emotion: .focused, exitReason: .targetHit),
            Fixture(openDay: 1, closeDay: 1, ticker: "MSFT", direction: .short, setup: "Failed Breakout", entry: 428, exit: 421, stop: 432, target: 418, reviewed: true, followedPlan: true, mistake: nil, emotion: .calm, exitReason: .manual),
            Fixture(openDay: 3, closeDay: 3, ticker: "TSLA", direction: .long, setup: "VWAP Reclaim", entry: 182, exit: 176, stop: 179, target: 190, reviewed: true, followedPlan: false, mistake: "Moved stop", emotion: .anxious, exitReason: .stopHit),
            Fixture(openDay: 4, closeDay: 4, ticker: "NVDA", direction: .long, setup: "Trend Pullback", entry: 915, exit: 940, stop: 905, target: 950, reviewed: true, followedPlan: true, mistake: nil, emotion: .focused, exitReason: .manual),
            Fixture(openDay: 6, closeDay: 6, ticker: "AMD", direction: .long, setup: "Breakout Retest", entry: 161, exit: 158, stop: 157, target: 169, reviewed: false, followedPlan: true, mistake: nil, emotion: .unknown, exitReason: .manual),
            Fixture(openDay: 7, closeDay: 7, ticker: "META", direction: .short, setup: "Lower High", entry: 512, exit: 517, stop: 516, target: 500, reviewed: true, followedPlan: false, mistake: "Chased entry", emotion: .fomo, exitReason: .stopHit),
            Fixture(openDay: 7, closeDay: 7, ticker: "QQQ", direction: .long, setup: "Range Break", entry: 445, exit: 449, stop: 443, target: 452, reviewed: true, followedPlan: true, mistake: nil, emotion: .calm, exitReason: .partial),
            Fixture(openDay: 9, closeDay: 9, ticker: "NFLX", direction: .long, setup: "News Continuation", entry: 626, exit: 632, stop: 620, target: 642, reviewed: false, followedPlan: true, mistake: nil, emotion: .unknown, exitReason: .manual),
            Fixture(openDay: 11, closeDay: 11, ticker: "SPY", direction: .short, setup: "Reversal", entry: 528, exit: 525, stop: 530, target: 522, reviewed: true, followedPlan: true, mistake: nil, emotion: .focused, exitReason: .targetHit),
            Fixture(openDay: 11, closeDay: 11, ticker: "IWM", direction: .short, setup: "Breakdown", entry: 206, exit: 211, stop: 209, target: 200, reviewed: true, followedPlan: false, mistake: "Oversized", emotion: .frustrated, exitReason: .stopHit),
            Fixture(openDay: -18, closeDay: 15, ticker: "VTI", direction: .long, setup: "Core Holding", entry: 248, exit: 263, stop: 238, target: 265, reviewed: true, followedPlan: true, mistake: nil, emotion: .calm, exitReason: .targetHit),
            Fixture(openDay: 15, closeDay: 15, ticker: "CRM", direction: .long, setup: "Earnings Drift", entry: 287, exit: 294, stop: 283, target: 300, reviewed: true, followedPlan: true, mistake: nil, emotion: .calm, exitReason: .manual),
            Fixture(openDay: 18, closeDay: 18, ticker: "COIN", direction: .long, setup: "Momentum", entry: 228, exit: 219, stop: 224, target: 240, reviewed: true, followedPlan: false, mistake: "Ignored market regime", emotion: .revenge, exitReason: .invalidated),
            Fixture(openDay: 19, closeDay: nil, ticker: "AMZN", direction: .long, setup: "Trend Pullback", entry: 184, exit: nil, stop: 181, target: 191, reviewed: false, followedPlan: true, mistake: nil, emotion: .unknown, exitReason: nil),
            Fixture(openDay: 22, closeDay: 22, ticker: "GOOGL", direction: .short, setup: "Failed Breakout", entry: 174, exit: 170, stop: 176, target: 168, reviewed: true, followedPlan: true, mistake: nil, emotion: .calm, exitReason: .targetHit),
            Fixture(openDay: 24, closeDay: 24, ticker: "BABA", direction: .long, setup: "Gap Fill", entry: 81, exit: 78, stop: 79, target: 86, reviewed: false, followedPlan: true, mistake: nil, emotion: .unknown, exitReason: .manual),
            Fixture(openDay: 25, closeDay: 25, ticker: "SMCI", direction: .short, setup: "Parabolic Fade", entry: 812, exit: 795, stop: 824, target: 780, reviewed: true, followedPlan: true, mistake: nil, emotion: .focused, exitReason: .manual),
            Fixture(openDay: 25, closeDay: 25, ticker: "PLTR", direction: .long, setup: "Breakout Retest", entry: 23, exit: 22, stop: 22.4, target: 25, reviewed: true, followedPlan: false, mistake: "Early entry", emotion: .hesitant, exitReason: .stopHit),
            Fixture(openDay: 28, closeDay: 28, ticker: "UBER", direction: .long, setup: "Relative Strength", entry: 73, exit: 76, stop: 71, target: 78, reviewed: true, followedPlan: true, mistake: nil, emotion: .calm, exitReason: .partial)
        ]

        return fixtures.compactMap { fixture in
            guard let openedAt = calendar.date(byAdding: .day, value: fixture.openDay - 1, to: monthStart) else {
                return nil
            }

            let closedAt = fixture.closeDay.flatMap { closeDay in
                calendar.date(byAdding: .day, value: closeDay - 1, to: monthStart)
                    .flatMap { calendar.date(byAdding: .hour, value: 3, to: $0) }
            }

            return makeTrade(from: fixture, openedAt: openedAt, closedAt: closedAt)
        }
    }

    private static func makeTrade(from fixture: Fixture, openedAt: Date, closedAt: Date?) -> Trade {
        let trade = Trade(
            openedAt: openedAt,
            closedAt: closedAt,
            ticker: fixture.ticker,
            market: "US",
            account: mockAccount,
            instrument: fixture.ticker == "QQQ" || fixture.ticker == "SPY" || fixture.ticker == "IWM" ? .etf : .stock,
            direction: fixture.direction,
            strategyName: fixture.followedPlan ? "Process A" : "Process Leak",
            setupType: fixture.setup,
            timeframe: "Intraday",
            thesis: "Mock review calendar trade for exploring daily summaries.",
            catalyst: fixture.reviewed ? "Planned setup" : "Needs review",
            confidenceScore: fixture.followedPlan ? 4 : 2,
            isAPlusSetup: fixture.followedPlan && fixture.exitReason != .stopHit,
            shareCount: 100,
            entryPrice: fixture.entry,
            exitPrice: fixture.exit,
            stopPrice: fixture.stop,
            targetPrice: fixture.target,
            plannedRiskAmount: 250,
            plannedRiskPercent: 0.5,
            commissions: 2.5,
            slippage: fixture.followedPlan ? 1 : 8,
            mae: abs(fixture.entry - fixture.stop) * 0.6,
            mfe: abs(fixture.target - fixture.entry) * 0.7,
            exitReason: closedAt == nil ? nil : fixture.exitReason
        )

        let context = TradeContext(
            marketRegime: fixture.followedPlan ? .trending : .choppy,
            vix: fixture.followedPlan ? 14 : 21,
            indexTrend: fixture.followedPlan ? "Aligned" : "Mixed",
            sectorStrength: fixture.followedPlan ? "Strong" : "Weak",
            newsDuringTrade: fixture.reviewed ? nil : "Unreviewed mock trade",
            timeOfDayTag: fixture.followedPlan ? "Morning" : "Lunch"
        )
        context.trade = trade
        trade.context = context

        if fixture.reviewed {
            let review = TradeReview(
                followedPlan: fixture.followedPlan,
                entryQuality: fixture.followedPlan ? 4 : 2,
                exitQuality: fixture.followedPlan ? 4 : 2,
                emotionalState: fixture.emotion,
                mistakeType: fixture.mistake,
                wouldRetake: fixture.followedPlan,
                postTradeNotes: "Mock review note for calendar testing.",
                whatWentRight: fixture.followedPlan ? "Waited for confirmation." : nil,
                whatWentWrong: fixture.followedPlan ? nil : fixture.mistake,
                oneImprovement: fixture.followedPlan ? "Keep using this checklist." : "Slow down and confirm entry criteria.",
                ruleCreatedOrUpdated: fixture.followedPlan ? nil : "Respect setup invalidation."
            )
            review.trade = trade
            trade.review = review
        }

        return trade
    }

    private struct Fixture {
        let openDay: Int
        let closeDay: Int?
        let ticker: String
        let direction: TradeDirection
        let setup: String
        let entry: Decimal
        let exit: Decimal?
        let stop: Decimal
        let target: Decimal
        let reviewed: Bool
        let followedPlan: Bool
        let mistake: String?
        let emotion: EmotionalState
        let exitReason: ExitReason?
    }
}
#endif

private struct ReviewCalendarTradeRow: View {
    let trade: Trade

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                TradeJournalRow(trade: trade)

                if trade.closedAt != nil {
                    Label("Opened \(TradeJournalFormatting.date(trade.openedAt))", systemImage: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
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
