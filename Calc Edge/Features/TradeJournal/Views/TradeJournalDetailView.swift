import Foundation
import SwiftUI

struct TradeJournalDetailView: View {
    let trade: Trade

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DetailSection(title: "Identification") {
                    DetailRow(label: "Trade ID", value: trade.tradeId.uuidString)
                    DetailRow(label: "Opened At", value: formatDate(trade.openedAt))
                    DetailRow(label: "Closed At", value: formatDate(trade.closedAt))
                    DetailRow(label: "Ticker", value: trade.ticker)
                    DetailRow(label: "Market", value: displayText(trade.market))
                    DetailRow(label: "Account", value: displayText(trade.account))
                    DetailRow(label: "Instrument", value: trade.instrument.rawValue.capitalized)
                    DetailRow(label: "Direction", value: trade.direction.rawValue.capitalized)
                }

                DetailSection(title: "Strategy") {
                    DetailRow(label: "Strategy Name", value: displayText(trade.strategyName))
                    DetailRow(label: "Setup Type", value: displayText(trade.setupType))
                    DetailRow(label: "Timeframe", value: displayText(trade.timeframe))
                    DetailRow(label: "Thesis", value: displayText(trade.thesis))
                    DetailRow(label: "Catalyst", value: displayText(trade.catalyst))
                    DetailRow(label: "Confidence Score", value: "\(trade.confidenceScore)")
                    DetailRow(label: "A+ Setup", value: formatBool(trade.isAPlusSetup ?? false))
                }

                DetailSection(title: "Prices") {
                    DetailRow(label: "Entry Price", value: formatDecimal(trade.entryPrice))
                    DetailRow(label: "Exit Price", value: formatDecimal(trade.exitPrice))
                    DetailRow(label: "Stop Price", value: formatDecimal(trade.stopPrice))
                    DetailRow(label: "Target Price", value: formatDecimal(trade.targetPrice))
                }

                DetailSection(title: "Risk") {
                    DetailRow(label: "Planned Risk Amount", value: formatDecimal(trade.plannedRiskAmount))
                    DetailRow(label: "Planned Risk Percent", value: formatDecimal(trade.plannedRiskPercent))
                    DetailRow(label: "Commissions", value: formatDecimal(trade.commissions))
                    DetailRow(label: "Slippage", value: formatDecimal(trade.slippage))
                    DetailRow(label: "MAE", value: formatDecimal(trade.mae))
                    DetailRow(label: "MFE", value: formatDecimal(trade.mfe))
                }

                DetailSection(title: "Exit") {
                    DetailRow(label: "Exit Reason", value: trade.exitReason?.rawValue.capitalized ?? "N/A")
                }

                DetailSection(title: "Context") {
                    if let context = trade.context {
                        DetailRow(label: "Market Regime", value: context.marketRegime.rawValue.capitalized)
                        DetailRow(label: "VIX", value: formatDecimal(context.vix))
                        DetailRow(label: "Index Trend", value: displayText(context.indexTrend))
                        DetailRow(label: "Sector Strength", value: displayText(context.sectorStrength))
                        DetailRow(label: "News During Trade", value: displayText(context.newsDuringTrade))
                        DetailRow(label: "Time Of Day", value: displayText(context.timeOfDayTag))
                    } else {
                        Text("No market context attached.")
                            .foregroundStyle(.secondary)
                    }
                }

                DetailSection(title: "Review") {
                    if let review = trade.review {
                        DetailRow(label: "Followed Plan", value: formatBool(review.followedPlan))
                        DetailRow(label: "Entry Quality", value: "\(review.entryQuality)")
                        DetailRow(label: "Exit Quality", value: "\(review.exitQuality)")
                        DetailRow(label: "Emotional State", value: review.emotionalState.rawValue.capitalized)
                        DetailRow(label: "Mistake Type", value: displayText(review.mistakeType))
                        DetailRow(label: "Would Retake", value: formatBool(review.wouldRetake))
                        DetailRow(label: "Post Trade Notes", value: displayText(review.postTradeNotes))
                        DetailRow(label: "What Went Right", value: displayText(review.whatWentRight))
                        DetailRow(label: "What Went Wrong", value: displayText(review.whatWentWrong))
                        DetailRow(label: "One Improvement", value: displayText(review.oneImprovement))
                        DetailRow(label: "Rule Updated", value: displayText(review.ruleCreatedOrUpdated))
                    } else {
                        Text("No review attached.")
                            .foregroundStyle(.secondary)
                    }
                }

                DetailSection(title: "Legs") {
                    if trade.legs.isEmpty {
                        Text("No legs attached.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(trade.legs) { leg in
                            VStack(alignment: .leading, spacing: 8) {
                                DetailRow(label: "Symbol", value: displayText(leg.symbol))
                                DetailRow(label: "Instrument", value: leg.legInstrument.rawValue.capitalized)
                                DetailRow(label: "Quantity", value: formatDecimal(leg.quantity))
                                DetailRow(label: "Entry Price", value: formatDecimal(leg.entryPrice))
                                DetailRow(label: "Exit Price", value: formatDecimal(leg.exitPrice))
                                DetailRow(label: "Option Expiration", value: formatDate(leg.optionExpiration))
                                DetailRow(label: "Option Strike", value: formatDecimal(leg.optionStrike))
                                DetailRow(label: "Option Type", value: displayText(leg.optionType))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                DetailSection(title: "Attachments") {
                    if trade.attachments.isEmpty {
                        Text("No attachments.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(trade.attachments) { attachment in
                            VStack(alignment: .leading, spacing: 8) {
                                DetailRow(label: "Kind", value: attachment.kind)
                                DetailRow(label: "Created At", value: formatDate(attachment.createdAt))
                                DetailRow(label: "Note", value: displayText(attachment.note))
                                DetailRow(label: "Image Data", value: formatImageData(attachment.imageData))
                                DetailRow(label: "URL", value: displayText(attachment.urlString))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(trade.ticker)
    }

    private func displayText(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "N/A" }
        return value
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "N/A" }
        return date.formatted()
    }

    private func formatDecimal(_ value: Decimal?) -> String {
        guard let value else { return "N/A" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private func formatBool(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }

    private func formatImageData(_ data: Data?) -> String {
        guard let data else { return "No" }
        return "Yes (\(data.count) bytes)"
    }
}
