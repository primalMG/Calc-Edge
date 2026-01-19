import Foundation
import SwiftData

@Model
final class TradeReview {
    var followedPlan: Bool
    var entryQuality: Int
    var exitQuality: Int
    var emotionalState: EmotionalState
    var mistakeType: String?
    var wouldRetake: Bool

    @Attribute(.externalStorage) var postTradeNotes: String?
    @Attribute(.externalStorage) var whatWentRight: String?
    @Attribute(.externalStorage) var whatWentWrong: String?
    var oneImprovement: String?
    var ruleCreatedOrUpdated: String?

    init(
        followedPlan: Bool = true,
        entryQuality: Int = 3,
        exitQuality: Int = 3,
        emotionalState: EmotionalState = .unknown,
        mistakeType: String? = nil,
        wouldRetake: Bool = true,
        postTradeNotes: String? = nil,
        whatWentRight: String? = nil,
        whatWentWrong: String? = nil,
        oneImprovement: String? = nil,
        ruleCreatedOrUpdated: String? = nil
    ) {
        self.followedPlan = followedPlan
        self.entryQuality = max(1, min(5, entryQuality))
        self.exitQuality = max(1, min(5, exitQuality))
        self.emotionalState = emotionalState
        self.mistakeType = mistakeType
        self.wouldRetake = wouldRetake
        self.postTradeNotes = postTradeNotes
        self.whatWentRight = whatWentRight
        self.whatWentWrong = whatWentWrong
        self.oneImprovement = oneImprovement
        self.ruleCreatedOrUpdated = ruleCreatedOrUpdated
    }
}
