import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity

        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if width + size.width > maxWidth {
                width = 0
                height += rowHeight + spacing
                rowHeight = 0
            }

            width += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Preview helpers

private struct TagChip: View {
    let text: String
    var multiline: Bool = false

    var body: some View {
        Text(text)
            .lineLimit(multiline ? nil : 1)
            // If you want chips to size to their text (common for tags):
            .fixedSize(horizontal: true, vertical: multiline)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.blue.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.blue.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(10)
    }
}

private struct FlowPreviewContainer: View {
    let title: String
    let width: CGFloat
    let spacing: CGFloat
    let sizeCategory: ContentSizeCategory
    let tags: [String]
    var multilineChips: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)

            FlowLayout(spacing: spacing) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(text: tag, multiline: multilineChips)
                }
            }
            .padding(12)
            .frame(width: width, alignment: .leading)
            .background(.gray.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.gray.opacity(0.35), lineWidth: 1)
            )
            .cornerRadius(14)

            Text("Width: \(Int(width))  •  Spacing: \(Int(spacing))  •  Type: \(String(describing: sizeCategory))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding()
        .environment(\.sizeCategory, sizeCategory)
    }
}

// MARK: - Previews

#Preview("FlowLayout (Basic)") {
    FlowPreviewContainer(
        title: "Basic tags",
        width: 360,
        spacing: 8,
        sizeCategory: .large,
        tags: ["SwiftUI", "iOS", "UI", "Backend", "Bugs", "Design", "QA", "Release", "Docs"]
    )
}

#Preview("FlowLayout (Narrow width)") {
    FlowPreviewContainer(
        title: "Narrow container (more wrapping)",
        width: 200,
        spacing: 8,
        sizeCategory: .large,
        tags: ["SwiftUI", "iOS", "Accessibility", "Dark Mode", "Internationalization", "Shipping"]
    )
}

#Preview("FlowLayout (Long items)") {
    FlowPreviewContainer(
        title: "Long items that must wrap",
        width: 320,
        spacing: 8,
        sizeCategory: .large,
        tags: [
            "Very long label that should definitely wrap to the next line",
            "Another long-ish tag for good measure",
            "Short",
            "Medium length"
        ]
    )
}

#Preview("FlowLayout (Single unbreakable word)") {
    FlowPreviewContainer(
        title: "Extremely long single word (edge case)",
        width: 320,
        spacing: 8,
        sizeCategory: .large,
        tags: [
            "Short",
            "SupercalifragilisticexpialidociousSupercalifragilisticexpialidocious",
            "Another"
        ]
    )
}

#Preview("FlowLayout (Multiline chips)") {
    FlowPreviewContainer(
        title: "Chips that can be multi-line",
        width: 320,
        spacing: 8,
        sizeCategory: .large,
        tags: ["Two\nLines", "This is\na 3-line\nlabel", "Short", "Another tag"],
        multilineChips: true
    )
}

#Preview("FlowLayout (Emoji + non-Latin)") {
    FlowPreviewContainer(
        title: "Emoji & non-Latin text",
        width: 340,
        spacing: 8,
        sizeCategory: .large,
        tags: ["🧠 Brain", "🔥 Hotfix", "✅ Done", "🚀 Launch", "日本語", "Tiếng Việt", "Deutsch", "Français"]
    )
}

#Preview("FlowLayout (Dynamic Type XXL)") {
    FlowPreviewContainer(
        title: "Large Dynamic Type",
        width: 360,
        spacing: 10,
        sizeCategory: .accessibilityExtraExtraExtraLarge,
        tags: ["Accessibility", "Bigger text", "Wraps sooner", "Buttons", "Labels", "More tags"]
    )
}

#Preview("FlowLayout (Zero spacing)") {
    FlowPreviewContainer(
        title: "Zero spacing (edge case)",
        width: 320,
        spacing: 0,
        sizeCategory: .large,
        tags: ["A", "BB", "CCC", "DDDD", "EEEEE", "FFFFFF", "GGGGGGG", "HHHHHHHH"]
    )
}
