import SwiftUI

struct FormSectionContainer<Content: View>: View {
    let title: String
    let style: FormSectionContainerStyle
    let content: Content

    init(
        _ title: String,
        style: FormSectionContainerStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.style = style
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: style.outerSpacing) {
            titleView

            VStack(alignment: .leading, spacing: style.contentSpacing) {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(style.padding)
        .background(style.background)
        .clipShape(.rect(cornerRadius: style.cornerRadius))
    }

    @ViewBuilder
    private var titleView: some View {
        if style.usesBoldTitle {
            Text(title)
                .font(style.titleFont)
                .bold()
        } else {
            Text(title)
                .font(style.titleFont)
        }
    }
}

struct FormSectionContainerStyle {
    let titleFont: Font
    let usesBoldTitle: Bool
    let outerSpacing: CGFloat
    let contentSpacing: CGFloat
    let padding: CGFloat
    let cornerRadius: CGFloat
    let background: AnyShapeStyle

    static let standard = FormSectionContainerStyle(
        titleFont: .headline,
        usesBoldTitle: false,
        outerSpacing: 10,
        contentSpacing: 10,
        padding: 16,
        cornerRadius: 8,
        background: AnyShapeStyle(.thinMaterial)
    )

    static let journal = FormSectionContainerStyle(
        titleFont: .headline,
        usesBoldTitle: false,
        outerSpacing: 12,
        contentSpacing: 12,
        padding: 16,
        cornerRadius: 12,
        background: AnyShapeStyle(.thinMaterial)
    )

    static let info = FormSectionContainerStyle(
        titleFont: .title3,
        usesBoldTitle: true,
        outerSpacing: 12,
        contentSpacing: 12,
        padding: 16,
        cornerRadius: 14,
        background: infoBackground
    )

    private static var infoBackground: AnyShapeStyle {
        #if os(iOS)
        AnyShapeStyle(.gray.tertiary.opacity(0.8))
        #else
        AnyShapeStyle(.thinMaterial)
        #endif
    }
}
