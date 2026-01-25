import SwiftUI

struct ExitSection: View {
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Exit") {
            Picker("Exit Reason", selection: $trade.exitReason) {
                Text("None")
                    .tag(ExitReason?.none)

                ForEach(ExitReason.allCases, id: \.self) { reason in
                    Text(reason.rawValue.capitalized)
                        .tag(Optional(reason))
                }
            }
        }
    }
}
