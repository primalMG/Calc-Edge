import SwiftUI

struct AttachmentsSection: View {
    @Bindable var trade: Trade

    var body: some View {
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
    }

    private func removeAttachment(_ attachment: TradeAttachment) {
        if let index = trade.attachments.firstIndex(where: { $0 === attachment }) {
            trade.attachments.remove(at: index)
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
