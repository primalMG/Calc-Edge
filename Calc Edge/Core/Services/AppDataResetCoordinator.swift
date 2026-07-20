import Foundation
import SwiftData

@MainActor
@Observable
final class AppDataResetCoordinator {
    private(set) var phase: AppDataResetPhase = .idle
    private(set) var resetGeneration = UUID()
    private(set) var outcome: AppDataResetOutcome?

    private var dataViewsReleaseContinuation: CheckedContinuation<Void, Never>?
    private var didReleaseDataViews = false

    var isResetting: Bool {
        phase != .idle
    }

    func clearAllData(in modelContext: ModelContext) {
        guard !isResetting else { return }

        outcome = nil
        didReleaseDataViews = false
        resetGeneration = UUID()
        phase = .preparing

        Task { @MainActor [weak self] in
            guard let self else { return }

            await waitForDataViewsToBeReleased()
            phase = .deleting

            do {
                let deletedCount = try AppDataResetService.clearAllData(in: modelContext)
                outcome = AppDataResetOutcome(result: .success(deletedCount: deletedCount))
            } catch {
                modelContext.rollback()
                outcome = AppDataResetOutcome(result: .failure(message: error.localizedDescription))
            }

            phase = .idle
        }
    }

    func dataBackedViewsDidDisappear() {
        guard phase == .preparing else { return }

        didReleaseDataViews = true
        dataViewsReleaseContinuation?.resume()
        dataViewsReleaseContinuation = nil
    }

    func consumeOutcome(_ outcomeID: AppDataResetOutcome.ID) {
        guard outcome?.id == outcomeID else { return }
        outcome = nil
    }

    private func waitForDataViewsToBeReleased() async {
        guard !didReleaseDataViews else { return }

        await withCheckedContinuation { continuation in
            dataViewsReleaseContinuation = continuation
        }
    }
}
