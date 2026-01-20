//
//  NewEditJournalSheet.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 20/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct NewEditJournalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var trade: Trade

    @State private var isNew: Bool = false

    var body: some View {
        HStack {
            Form {
                Section("Identification") {
                    LabeledContent("Ticker") {
                        TextField("", text: $trade.ticker)
//                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }

                    LabeledContent("Market") {
                        TextField("", text: optionalTextBinding($trade.market))
                    }

                    LabeledContent("Account") {
                        TextField("", text: optionalTextBinding($trade.account))
                    }

                    Picker("Instrument", selection: $trade.instrument) {
                        ForEach(InstrumentType.allCases, id: \.self) { instrument in
                            Text(instrument.rawValue.capitalized)
                                .tag(instrument)
                        }
                    }

                    Picker("Direction", selection: $trade.direction) {
                        ForEach(TradeDirection.allCases, id: \.self) { direction in
                            Text(direction.rawValue.capitalized)
                                .tag(direction)
                        }
                    }

                    DatePicker("Opened At", selection: $trade.openedAt, displayedComponents: [.date, .hourAndMinute])

                    Toggle("Closed Trade", isOn: closedTradeBinding)

                    if trade.closedAt != nil {
                        DatePicker("Closed At", selection: closedAtBinding, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("Strategy") {
                    LabeledContent("Strategy Name") {
                        TextField("", text: optionalTextBinding($trade.strategyName))
                    }

                    LabeledContent("Setup Type") {
                        TextField("", text: optionalTextBinding($trade.setupType))
                    }

                    LabeledContent("Timeframe") {
                        TextField("", text: optionalTextBinding($trade.timeframe))
                    }

                    LabeledContent("Thesis") {
                        TextField("", text: optionalTextBinding($trade.thesis))
                    }

                    LabeledContent("Catalyst") {
                        TextField("", text: optionalTextBinding($trade.catalyst))
                    }

                    Stepper("Confidence Score: \(trade.confidenceScore)", value: $trade.confidenceScore, in: 1...5)

                    Toggle("A+ Setup", isOn: $trade.isAPlusSetup)
                }

                Section("Prices") {
                    LabeledContent("Entry Price") {
                        TextField("", text: optionalDecimalBinding($trade.entryPrice))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("Exit Price") {
                        TextField("", text: optionalDecimalBinding($trade.exitPrice))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("Stop Price") {
                        TextField("", text: optionalDecimalBinding($trade.stopPrice))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("Target Price") {
                        TextField("", text: optionalDecimalBinding($trade.targetPrice))
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                }

                Section("Risk") {
                    LabeledContent("Planned Risk Amount") {
                        TextField("", text: optionalDecimalBinding($trade.plannedRiskAmount))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("Planned Risk Percent") {
                        TextField("", text: optionalDecimalBinding($trade.plannedRiskPercent))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("Commissions") {
                        TextField("", text: optionalDecimalBinding($trade.commissions))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("Slippage") {
                        TextField("", text: optionalDecimalBinding($trade.slippage))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("MAE") {
                        TextField("", text: optionalDecimalBinding($trade.mae))
                            .textFieldStyle(CustomTextFieldStyle())
                    }

                    LabeledContent("MFE") {
                        TextField("", text: optionalDecimalBinding($trade.mfe))
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                }

                Section("Exit") {
                    Picker("Exit Reason", selection: $trade.exitReason) {
                        Text("None")
                            .tag(ExitReason?.none)

                        ForEach(ExitReason.allCases, id: \.self) { reason in
                            Text(reason.rawValue.capitalized)
                                .tag(Optional(reason))
                        }
                    }
                }

                Section("Market Context") {
                    if let context = trade.context {
                        TradeContextEditor(context: context) {
                            trade.context = nil
                        }
                    } else {
                        Button("Add Market Context") {
                            trade.context = TradeContext()
                        }
                    }
                }

                Section("Review") {
                    if let review = trade.review {
                        TradeReviewEditor(review: review) {
                            trade.review = nil
                        }
                    } else {
                        Button("Add Review") {
                            trade.review = TradeReview()
                        }
                    }
                }

                Section("Legs") {
                    if trade.legs.isEmpty {
                        Text("No legs added yet.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(trade.legs) { leg in
                        TradeLegEditor(leg: leg) {
                            removeLeg(leg)
                        }
                    }

                    Button("Add Leg") {
                        trade.legs.append(TradeLeg())
                    }
                }

                Section("Attachments") {
                    if trade.attachments.isEmpty {
                        Text("No attachments added yet.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(trade.attachments) { attachment in
                        TradeAttachmentEditor(attachment: attachment) {
                            removeAttachment(attachment)
                        }
                    }

                    Button("Add Attachment") {
                        trade.attachments.append(TradeAttachment(kind: ""))
                    }
                }

                HStack {
                    Button(isNew ? "Save" : "Update") {
                        save()
                    }
                    .tint(.green)

                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(.red)
                }
            }
            .padding()
        }
        .onAppear {
            if trade.ticker.isEmpty {
                isNew = true
            }
        }
    }

    private var closedTradeBinding: Binding<Bool> {
        Binding(
            get: { trade.closedAt != nil },
            set: { isClosed in
                if isClosed {
                    trade.closedAt = trade.closedAt ?? Date()
                } else {
                    trade.closedAt = nil
                }
            }
        )
    }

    private var closedAtBinding: Binding<Date> {
        Binding(
            get: { trade.closedAt ?? Date() },
            set: { trade.closedAt = $0 }
        )
    }

    private func removeLeg(_ leg: TradeLeg) {
        if let index = trade.legs.firstIndex(where: { $0 === leg }) {
            trade.legs.remove(at: index)
        }
    }

    private func removeAttachment(_ attachment: TradeAttachment) {
        if let index = trade.attachments.firstIndex(where: { $0 === attachment }) {
            trade.attachments.remove(at: index)
        }
    }

    private func save() {
        trade.ticker = trade.ticker.uppercased()
        if isNew {
            modelContext.insert(trade)
        }
        dismiss()
    }
}

private struct TradeContextEditor: View {
    @Bindable var context: TradeContext
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Picker("Market Regime", selection: $context.marketRegime) {
                ForEach(MarketRegime.allCases, id: \.self) { regime in
                    Text(regime.rawValue.capitalized)
                        .tag(regime)
                }
            }

            LabeledContent("VIX") {
                TextField("", text: optionalDecimalBinding($context.vix))
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("Index Trend") {
                TextField("", text: optionalTextBinding($context.indexTrend))
            }

            LabeledContent("Sector Strength") {
                TextField("", text: optionalTextBinding($context.sectorStrength))
            }

            LabeledContent("News During Trade") {
                TextField("", text: optionalTextBinding($context.newsDuringTrade))
            }

            LabeledContent("Time Of Day") {
                TextField("", text: optionalTextBinding($context.timeOfDayTag))
            }

            Button("Remove Context") {
                onRemove()
            }
            .tint(.red)
        }
    }
}

private struct TradeReviewEditor: View {
    @Bindable var review: TradeReview
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Toggle("Followed Plan", isOn: $review.followedPlan)

            Stepper("Entry Quality: \(review.entryQuality)", value: $review.entryQuality, in: 1...5)

            Stepper("Exit Quality: \(review.exitQuality)", value: $review.exitQuality, in: 1...5)

            Picker("Emotional State", selection: $review.emotionalState) {
                ForEach(EmotionalState.allCases, id: \.self) { state in
                    Text(state.rawValue.capitalized)
                        .tag(state)
                }
            }

            Toggle("Would Retake", isOn: $review.wouldRetake)

            LabeledContent("Mistake Type") {
                TextField("", text: optionalTextBinding($review.mistakeType))
            }

            LabeledContent("Post Trade Notes") {
                TextField("", text: optionalTextBinding($review.postTradeNotes))
            }

            LabeledContent("What Went Right") {
                TextField("", text: optionalTextBinding($review.whatWentRight))
            }

            LabeledContent("What Went Wrong") {
                TextField("", text: optionalTextBinding($review.whatWentWrong))
            }

            LabeledContent("One Improvement") {
                TextField("", text: optionalTextBinding($review.oneImprovement))
            }

            LabeledContent("Rule Updated") {
                TextField("", text: optionalTextBinding($review.ruleCreatedOrUpdated))
            }

            Button("Remove Review") {
                onRemove()
            }
            .tint(.red)
        }
    }
}

private struct TradeLegEditor: View {
    @Bindable var leg: TradeLeg
    let onRemove: () -> Void

    var body: some View {
        DisclosureGroup(legTitle) {
            VStack(spacing: 12) {
                LabeledContent("Symbol") {
                    TextField("", text: optionalTextBinding($leg.symbol))
                }

                Picker("Instrument", selection: $leg.legInstrument) {
                    ForEach(InstrumentType.allCases, id: \.self) { instrument in
                        Text(instrument.rawValue.capitalized)
                            .tag(instrument)
                    }
                }

                LabeledContent("Quantity") {
                    TextField("", text: decimalBinding($leg.quantity))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                LabeledContent("Entry Price") {
                    TextField("", text: optionalDecimalBinding($leg.entryPrice))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                LabeledContent("Exit Price") {
                    TextField("", text: optionalDecimalBinding($leg.exitPrice))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                DatePicker("Option Expiration", selection: optionExpirationBinding, displayedComponents: [.date])

                LabeledContent("Option Strike") {
                    TextField("", text: optionalDecimalBinding($leg.optionStrike))
                        .textFieldStyle(CustomTextFieldStyle())
                }

                LabeledContent("Option Type") {
                    TextField("", text: optionalTextBinding($leg.optionType))
                }

                Button("Remove Leg") {
                    onRemove()
                }
                .tint(.red)
            }
            .padding(.top, 8)
        }
    }

    private var legTitle: String {
        if let symbol = leg.symbol, !symbol.isEmpty {
            return symbol
        }
        return "Trade Leg"
    }

    private var optionExpirationBinding: Binding<Date> {
        Binding(
            get: { leg.optionExpiration ?? Date() },
            set: { leg.optionExpiration = $0 }
        )
    }
}

private struct TradeAttachmentEditor: View {
    @Bindable var attachment: TradeAttachment
    let onRemove: () -> Void

    var body: some View {
        DisclosureGroup(attachmentTitle) {
            VStack(spacing: 12) {
                LabeledContent("Kind") {
                    TextField("", text: $attachment.kind)
                }

                DatePicker("Created At", selection: $attachment.createdAt, displayedComponents: [.date, .hourAndMinute])

                LabeledContent("Note") {
                    TextField("", text: optionalTextBinding($attachment.note))
                }

                LabeledContent("URL") {
                    TextField("", text: optionalTextBinding($attachment.urlString))
                }

                Button("Remove Attachment") {
                    onRemove()
                }
                .tint(.red)
            }
            .padding(.top, 8)
        }
    }

    private var attachmentTitle: String {
        if !attachment.kind.isEmpty {
            return attachment.kind
        }
        return "Attachment"
    }
}

private func optionalTextBinding(_ binding: Binding<String?>) -> Binding<String> {
    Binding(
        get: { binding.wrappedValue ?? "" },
        set: { newValue in
            binding.wrappedValue = newValue.isEmpty ? nil : newValue
        }
    )
}

private func optionalDecimalBinding(_ binding: Binding<Decimal?>) -> Binding<String> {
    Binding(
        get: {
            guard let value = binding.wrappedValue else { return "" }
            return NSDecimalNumber(decimal: value).stringValue
        },
        set: { newValue in
            let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
            if cleaned.isEmpty {
                binding.wrappedValue = nil
            } else if let decimal = Decimal(string: cleaned) {
                binding.wrappedValue = decimal
            }
        }
    )
}

private func decimalBinding(_ binding: Binding<Decimal>) -> Binding<String> {
    Binding(
        get: {
            NSDecimalNumber(decimal: binding.wrappedValue).stringValue
        },
        set: { newValue in
            let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
            if cleaned.isEmpty {
                binding.wrappedValue = 0
            } else if let decimal = Decimal(string: cleaned) {
                binding.wrappedValue = decimal
            }
        }
    )
}

#Preview {
    NewEditJournalSheet(trade: Trade(ticker: "AAPL"))
        .modelContainer(for: [Trade.self, TradeLeg.self, TradeContext.self, TradeReview.self, TradeAttachment.self], inMemory: true)
}
