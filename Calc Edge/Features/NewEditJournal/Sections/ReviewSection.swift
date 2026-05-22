import SwiftUI
import SwiftData

struct ReviewSection: View {
    @Bindable var trade: Trade

    var body: some View {
        reviewSectionLayout {
            if let review = trade.review {
                TradeReviewEditor(review: review) {
                    trade.review = nil
                }
            } else {
                Button("Add Review") {
                    #if os(iOS)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        trade.review = TradeReview()
                    }
                    #else
                    trade.review = TradeReview()
                    #endif
                }
                #if os(iOS)
                .buttonStyle(.borderedProminent)
                .tint(Color.gray.gradient)
                .foregroundStyle(.primary)
                #endif
            }
        }
    }
    
    private func reviewSectionLayout<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(macOS)
        JournalSectionContainer("Review") {
            content()
        }
        #else
        content()
        #endif
    }
}

private struct TradeReviewEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TradingRule.title) private var rules: [TradingRule]

    @Bindable var review: TradeReview
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Followed Plan", isOn: $review.followedPlan)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("Would Retake?", isOn: $review.wouldRetake)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Stepper("Entry Quality: \(review.entryQuality)", value: $review.entryQuality, in: 1...5)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Stepper("Exit Quality: \(review.exitQuality)", value: $review.exitQuality, in: 1...5)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            JournalField("Emotional State") {
                JournalMenuPicker(review.emotionalState.rawValue.capitalized, selection: $review.emotionalState) {
                    ForEach(EmotionalState.allCases, id: \.self) { state in
                        Text(state.rawValue.capitalized)
                            .tag(state)
                    }
                }
            }
            
            
            JournalField("Mistake Type") {
                SuggestingOptionalTextField(field: .reviewMistakeType, text: $review.mistakeType)
#if os(iOS)
                    .textFieldStyle(JournalCustomTextFieldStyle())
#endif
            }
            
            JournalField("Post Trade Notes") {
                SuggestingOptionalTextField(field: .reviewPostTradeNotes, text: $review.postTradeNotes)
#if os(iOS)
                    .textFieldStyle(JournalCustomTextFieldStyle())
#endif
            }
            
            JournalField("What Went Right") {
                SuggestingOptionalTextField(field: .reviewWhatWentRight, text: $review.whatWentRight)
#if os(iOS)
                    .textFieldStyle(JournalCustomTextFieldStyle())
#endif
            }
            
            JournalField("What Went Wrong") {
                SuggestingOptionalTextField(field: .reviewWhatWentWrong, text: $review.whatWentWrong)
#if os(iOS)
                    .textFieldStyle(JournalCustomTextFieldStyle())
#endif
            }
            
            JournalField("One Improvement") {
                SuggestingOptionalTextField(field: .reviewOneImprovement, text: $review.oneImprovement)
#if os(iOS)
                    .textFieldStyle(JournalCustomTextFieldStyle())
#endif
            }
            
            JournalField("Rule Updated") {
                SuggestingOptionalTextField(field: .reviewRuleCreatedOrUpdated, text: $review.ruleCreatedOrUpdated)
#if os(iOS)
                    .textFieldStyle(JournalCustomTextFieldStyle())
#endif
            }

            if !activeRules.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rule Checks")
                        .font(.headline)

                    ForEach(activeRules) { rule in
                        RuleCheckRow(
                            rule: rule,
                            isFollowed: ruleFollowedBinding(for: rule)
                        )
                    }
                }
                .padding(.top, 4)
            }
            
            
            Button("Remove Review") {
                onRemove()
            }
            .tint(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.borderless)
        }
    }

    private var activeRules: [TradingRule] {
        rules.filter(\.isActive)
    }

    private func ruleFollowedBinding(for rule: TradingRule) -> Binding<Bool> {
        Binding {
            existingCheck(for: rule)?.followed ?? true
        } set: { newValue in
            let check = existingCheck(for: rule) ?? createCheck(for: rule)
            check.followed = newValue
            try? modelContext.save()
        }
    }

    private func existingCheck(for rule: TradingRule) -> TradeRuleCheck? {
        review.ruleChecks?.first { $0.rule?.ruleId == rule.ruleId }
    }

    private func createCheck(for rule: TradingRule) -> TradeRuleCheck {
        let check = TradeRuleCheck(followed: true, rule: rule, review: review)
        modelContext.insert(check)
        review.ruleChecks = (review.ruleChecks ?? []) + [check]
        return check
    }
}

private struct RuleCheckRow: View {
    let rule: TradingRule
    @Binding var isFollowed: Bool

    var body: some View {
        Toggle(isOn: $isFollowed) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.title.isEmpty ? "Untitled Rule" : rule.title)
                    .font(.subheadline.weight(.semibold))

                if let prompt = rule.checklistPrompt, !prompt.isEmpty {
                    Text(prompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
    }
}
