import SwiftUI

struct ReviewSection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Review") {
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
    }
}

private struct TradeReviewEditor: View {
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
                Picker("", selection: $review.emotionalState) {
                    ForEach(EmotionalState.allCases, id: \.self) { state in
                        Text(state.rawValue.capitalized)
                            .tag(state)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
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
                .textFieldStyle(CustomTextFieldStyle())
                #endif
            }

            JournalField("What Went Right") {
                SuggestingOptionalTextField(field: .reviewWhatWentRight, text: $review.whatWentRight)
                #if os(iOS)
                .textFieldStyle(CustomTextFieldStyle())
                #endif
            }

            JournalField("What Went Wrong") {
                SuggestingOptionalTextField(field: .reviewWhatWentWrong, text: $review.whatWentWrong)
                #if os(iOS)
                .textFieldStyle(CustomTextFieldStyle())
                #endif
            }

            JournalField("One Improvement") {
                SuggestingOptionalTextField(field: .reviewOneImprovement, text: $review.oneImprovement)
                #if os(iOS)
                .textFieldStyle(CustomTextFieldStyle())
                #endif
            }

            JournalField("Rule Updated") {
                SuggestingOptionalTextField(field: .reviewRuleCreatedOrUpdated, text: $review.ruleCreatedOrUpdated)
                #if os(iOS)
                .textFieldStyle(CustomTextFieldStyle())
                #endif
            }
                

            Button("Remove Review") {
                onRemove()
            }
            .tint(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

#if os(macOS)
    private let columns = [
        GridItem(.flexible(minimum: 160), spacing: 12),
        GridItem(.flexible(minimum: 160), spacing: 12)
    ]
#else
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]
#endif
}
