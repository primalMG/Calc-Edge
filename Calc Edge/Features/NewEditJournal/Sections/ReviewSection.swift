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
