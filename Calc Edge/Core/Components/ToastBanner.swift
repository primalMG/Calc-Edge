//
//  ToastBanner.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 20/04/2026.
//

import Foundation
import SwiftUI

enum ToastState: Equatable {
    case success
    case info
    case warning
    case error

    var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success:
            return .green
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

struct ToastConfiguration: Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String?
    let state: ToastState
    let duration: TimeInterval

    init(
        id: UUID = UUID(),
        title: String,
        message: String? = nil,
        state: ToastState = .info,
        duration: TimeInterval = 2.5
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.state = state
        self.duration = duration
    }
}

struct ToastBanner: View {
    let configuration: ToastConfiguration

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: configuration.state.iconName)
                .font(.headline)
                .foregroundStyle(configuration.state.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(configuration.title)
                    .font(.subheadline.weight(.semibold))

                if let message = configuration.message,
                   !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(configuration.state.tint.opacity(0.25), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard let message = configuration.message,
              !message.isEmpty else {
            return configuration.title
        }

        return "\(configuration.title). \(message)"
    }
}

private struct ToastPresenter: ViewModifier {
    @Binding var toast: ToastConfiguration?
    let edge: VerticalEdge

    func body(content: Content) -> some View {
        content
            .overlay(alignment: edge == .top ? .top : .bottom) {
                if let toast {
                    ToastBanner(configuration: toast)
                        .padding(.horizontal, 16)
                        .padding(edge == .top ? .top : .bottom, 12)
                        .transition(transition)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: toast?.id)
            .task(id: toast?.id) {
                await dismissAfterDelayIfNeeded()
            }
    }

    @MainActor
    private func dismissAfterDelayIfNeeded() async {
        guard let toast else {
            return
        }

        let duration = max(0, toast.duration)
        guard duration > 0 else {
            return
        }

        let nanoseconds = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)

        guard !Task.isCancelled,
              self.toast?.id == toast.id else {
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            self.toast = nil
        }
    }

    private var transition: AnyTransition {
        switch edge {
        case .top:
            return .move(edge: .top).combined(with: .opacity)
        case .bottom:
            return .move(edge: .bottom).combined(with: .opacity)
        }
    }
}

extension View {
    func toast(_ toast: Binding<ToastConfiguration?>, edge: VerticalEdge = .top) -> some View {
        modifier(ToastPresenter(toast: toast, edge: edge))
    }
}
