enum AppDataResetResult: Equatable {
    case success(deletedCount: Int)
    case failure(message: String)
}
