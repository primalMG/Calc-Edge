import SwiftUI

struct PrivacyTermsView: View {
    var body: some View {
        #if os(iOS)
        List {
            Section("Privacy") {
                LegalTextRow(
                    title: "No tracking",
                    detail: "Calc Edge does not track you, profile your behaviour, sell personal data, or show advertising."
                )

                LegalTextRow(
                    title: "Data storage",
                    detail: "The trading journals, notes, accounts, calculations, rulebook entries, and playbook setups you create are stored in your app data and may sync through your private iCloud account when iCloud is enabled."
                )

                LegalTextRow(
                    title: "Third-party data",
                    detail: "The app does not intentionally share your journal content with third-party analytics or advertising services."
                )
            }

            Section("Terms") {
                LegalTextRow(
                    title: "Educational use",
                    detail: "Calc Edge is a journaling and calculation tool. It does not provide financial, investment, tax, or legal advice."
                )

                LegalTextRow(
                    title: "Your responsibility",
                    detail: "You are responsible for checking calculations, trade records, imports, and any decisions made from information entered into the app."
                )

                LegalTextRow(
                    title: "Data deletion",
                    detail: "You can clear app-created data from the Clear All Data screen. This action is destructive and cannot be undone from inside the app."
                )
            }
        }
        .navigationTitle("Privacy & Terms")
        #else
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                InfoSection(title: "Privacy") {
                    LegalTextRow(
                        title: "No tracking",
                        detail: "Calc Edge does not track you, profile your behaviour, sell personal data, or show advertising."
                    )

                    Divider()

                    LegalTextRow(
                        title: "Data storage",
                        detail: "The trading journals, notes, accounts, calculations, rulebook entries, and playbook setups you create are stored in your app data and may sync through your private iCloud account when iCloud is enabled."
                    )

                    Divider()

                    LegalTextRow(
                        title: "Third-party data",
                        detail: "The app does not intentionally share your journal content with third-party analytics or advertising services."
                    )
                }

                InfoSection(title: "Terms") {
                    LegalTextRow(
                        title: "Educational use",
                        detail: "Calc Edge is a journaling and calculation tool. It does not provide financial, investment, tax, or legal advice."
                    )

                    Divider()

                    LegalTextRow(
                        title: "Your responsibility",
                        detail: "You are responsible for checking calculations, trade records, imports, and any decisions made from information entered into the app."
                    )

                    Divider()

                    LegalTextRow(
                        title: "Data deletion",
                        detail: "You can clear app-created data from the Clear All Data screen. This action is destructive and cannot be undone from inside the app."
                    )
                }
            }
            .frame(maxWidth: 820, alignment: .leading)
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("Privacy & Terms")
        #endif
    }

    #if os(macOS)
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Privacy & Terms")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("A clear summary of how Calc Edge handles your app-created data.")
                .foregroundStyle(.secondary)
        }
    }
    #endif
}

private struct LegalTextRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PrivacyTermsView()
    }
}
