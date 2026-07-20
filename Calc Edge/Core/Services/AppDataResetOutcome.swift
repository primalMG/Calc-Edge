import Foundation

struct AppDataResetOutcome: Equatable, Identifiable {
    let id = UUID()
    let result: AppDataResetResult
}
