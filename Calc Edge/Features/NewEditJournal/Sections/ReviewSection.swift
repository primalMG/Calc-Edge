import SwiftUI

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
            
            
            Button("Remove Review") {
                onRemove()
            }
            .tint(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.borderless)
        }
    }
    
#if os(macOS)
    private let columns = [
        GridItem(.flexible(minimum: 160), spacing: 12),
        GridItem(.flexible(minimum: 160), spacing: 12)
    ]
#else
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 15)
    ]
#endif
}
