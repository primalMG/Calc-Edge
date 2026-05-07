import SwiftUI

struct AttachmentsSection: View {
    @Bindable var trade: Trade
    
    private var attachments: [TradeAttachment] {
        trade.attachments ?? []
    }

    var body: some View {
        JournalSectionContainer("Attachments") {
            if attachments.isEmpty {
                Text("No attachments added yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(attachments) { attachment in
                TradeAttachmentEditor(attachment: attachment) {
                    removeAttachment(attachment)
                }
            }

            Button("Add Attachment") {
                if trade.attachments == nil {
                    trade.attachments = []
                }
                trade.attachments?.append(TradeAttachment(kind: ""))
            }
            #if os(iOS)
            .buttonStyle(.borderedProminent)
            .tint(Color.gray.gradient)
            .foregroundStyle(.primary)
            .padding(.top, 10)
            #endif
        }
    }

    private func removeAttachment(_ attachment: TradeAttachment) {
        if let index = trade.attachments?.firstIndex(where: { $0 === attachment }) {
            trade.attachments?.remove(at: index)
        }
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
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                #if os(iOS)
                .tint(Color.gray.gradient)
                .buttonStyle(.borderedProminent)
                #endif
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
