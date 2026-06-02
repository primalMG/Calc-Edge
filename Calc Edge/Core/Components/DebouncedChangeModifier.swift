import SwiftUI

struct DebouncedChangeModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let delay: Duration
    let action: @MainActor () -> Void

    @State private var pendingTask: Task<Void, Never>?
    @State private var hasPendingChange = false

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, _ in
                scheduleAction()
            }
            .onDisappear {
                flushPendingAction()
            }
    }

    private func scheduleAction() {
        hasPendingChange = true
        pendingTask?.cancel()
        pendingTask = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                flushPendingAction()
            }
        }
    }

    private func flushPendingAction() {
        pendingTask?.cancel()
        pendingTask = nil

        guard hasPendingChange else { return }
        hasPendingChange = false
        action()
    }
}

extension View {
    func onDebouncedChange<Value: Equatable>(
        of value: Value,
        delay: Duration = .milliseconds(750),
        perform action: @escaping @MainActor () -> Void
    ) -> some View {
        modifier(DebouncedChangeModifier(value: value, delay: delay, action: action))
    }
}
