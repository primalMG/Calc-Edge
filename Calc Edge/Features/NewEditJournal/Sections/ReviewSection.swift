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
        Form {
            Toggle("Followed Plan", isOn: $review.followedPlan)

            Stepper("Entry Quality: \(review.entryQuality)", value: $review.entryQuality, in: 1...5)

            Stepper("Exit Quality: \(review.exitQuality)", value: $review.exitQuality, in: 1...5)

            Picker("Emotional State", selection: $review.emotionalState) {
                ForEach(EmotionalState.allCases, id: \.self) { state in
                    Text(state.rawValue.capitalized)
                        .tag(state)
                }
            }

            Toggle("Would Retake?", isOn: $review.wouldRetake)

            LabeledContent("Mistake Type:") {
                SuggestingOptionalTextField(field: .reviewMistakeType, text: $review.mistakeType)
            }

            LabeledContent("Post Trade Notes:") {
                SuggestingOptionalTextField(field: .reviewPostTradeNotes, text: $review.postTradeNotes)
            }

            LabeledContent("What Went Right:") {
                SuggestingOptionalTextField(field: .reviewWhatWentRight, text: $review.whatWentRight)
            }

            LabeledContent("What Went Wrong:") {
                SuggestingOptionalTextField(field: .reviewWhatWentWrong, text: $review.whatWentWrong)
            }

            LabeledContent("One Improvement:") {
                SuggestingOptionalTextField(field: .reviewOneImprovement, text: $review.oneImprovement)
            }

            LabeledContent("Rule Updated:") {
                SuggestingOptionalTextField(field: .reviewRuleCreatedOrUpdated, text: $review.ruleCreatedOrUpdated)
            }

            Button("Remove Review") {
                onRemove()
            }
            .tint(.red)
        }
    }
}
