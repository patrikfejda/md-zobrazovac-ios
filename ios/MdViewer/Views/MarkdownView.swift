import SwiftUI

/// Minimal block-level Markdown renderer:
///   - `#`/`##`/`###` headings
///   - fenced code blocks (```)
///   - bullet (`- ` / `* `) and ordered (`1. `) lists
///   - horizontal rule (`---`)
///   - blank lines as paragraph separators
///   - inline formatting (**bold**, *italic*, [links](…), `code`) via
///     `AttributedString(markdown:)`
///   - images `![alt](path)` resolved to local files in the content cache
///
/// Intentionally small — if you need GFM tables, task lists, footnotes, etc.,
/// swap this for swift-markdown or markdown-ui.
struct MarkdownView: View {
    let text: String
    let fontScale: Double

    var body: some View {
        let blocks = MarkdownParser.parse(text)
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
    }

    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(inline(text))
                .font(.system(size: headingSize(level) * fontScale, weight: .bold))
                .padding(.top, level == 1 ? 8 : 4)
        case .paragraph(let text):
            Text(inline(text))
                .font(.system(size: 17 * fontScale))
                .fixedSize(horizontal: false, vertical: true)
        case .codeBlock(let language, let code):
            VStack(alignment: .leading, spacing: 4) {
                if let language, !language.isEmpty {
                    Text(language)
                        .font(.system(size: 11 * fontScale, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Text(code)
                    .font(.system(size: 14 * fontScale, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                    .textSelection(.enabled)
            }
        case .list(let items, let ordered):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(ordered ? "\(idx + 1)." : "•")
                            .font(.system(size: 17 * fontScale))
                            .foregroundStyle(.secondary)
                        Text(inline(item))
                            .font(.system(size: 17 * fontScale))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        case .horizontalRule:
            Divider()
        case .image(let alt, _):
            // TODO: resolve via ContentStore once you pass the entry path in.
            // For now we render the alt text as a placeholder.
            Text(alt.isEmpty ? "[obrázok]" : "[obrázok: \(alt)]")
                .font(.system(size: 14 * fontScale))
                .foregroundStyle(.secondary)
        }
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: 28
        case 2: 22
        case 3: 19
        default: 17
        }
    }

    private func inline(_ text: String) -> AttributedString {
        // AttributedString(markdown:) handles **bold**, *italic*, `code`, [links](...)
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return attributed
        }
        return AttributedString(text)
    }
}

// MARK: - Parser

enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case codeBlock(language: String?, code: String)
    case list(items: [String], ordered: Bool)
    case horizontalRule
    case image(alt: String, path: String)
}

enum MarkdownParser {
    static func parse(_ source: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        var i = 0
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                i += 1
                continue
            }

            if trimmed == "---" || trimmed == "***" {
                blocks.append(.horizontalRule)
                i += 1
                continue
            }

            if trimmed.hasPrefix("```") {
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count, !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                if i < lines.count { i += 1 } // consume closing fence
                blocks.append(.codeBlock(language: language.isEmpty ? nil : language, code: codeLines.joined(separator: "\n")))
                continue
            }

            if let (level, rest) = parseHeading(trimmed) {
                blocks.append(.heading(level: level, text: rest))
                i += 1
                continue
            }

            if isBulletLine(trimmed) || isOrderedLine(trimmed) {
                let ordered = isOrderedLine(trimmed)
                var items: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    if ordered, isOrderedLine(t) {
                        items.append(stripOrderedPrefix(t))
                    } else if !ordered, isBulletLine(t) {
                        items.append(stripBulletPrefix(t))
                    } else {
                        break
                    }
                    i += 1
                }
                blocks.append(.list(items: items, ordered: ordered))
                continue
            }

            if let img = parseImage(trimmed) {
                blocks.append(.image(alt: img.alt, path: img.path))
                i += 1
                continue
            }

            // Paragraph: collect contiguous non-empty, non-special lines.
            var paragraphLines: [String] = [trimmed]
            i += 1
            while i < lines.count {
                let t = lines[i].trimmingCharacters(in: .whitespaces)
                if t.isEmpty { break }
                if t.hasPrefix("#") || t.hasPrefix("```") || isBulletLine(t) || isOrderedLine(t) || t == "---" { break }
                paragraphLines.append(t)
                i += 1
            }
            blocks.append(.paragraph(paragraphLines.joined(separator: " ")))
        }
        return blocks
    }

    private static func parseHeading(_ line: String) -> (Int, String)? {
        var level = 0
        var idx = line.startIndex
        while idx < line.endIndex, line[idx] == "#", level < 6 {
            level += 1
            idx = line.index(after: idx)
        }
        guard level > 0, idx < line.endIndex, line[idx] == " " else { return nil }
        let rest = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
        return (level, rest)
    }

    private static func isBulletLine(_ s: String) -> Bool {
        s.hasPrefix("- ") || s.hasPrefix("* ")
    }

    private static func stripBulletPrefix(_ s: String) -> String {
        String(s.dropFirst(2))
    }

    private static func isOrderedLine(_ s: String) -> Bool {
        // crude: "N. text" where N is 1+ digits
        guard let dotRange = s.range(of: ". ") else { return false }
        let prefix = s[..<dotRange.lowerBound]
        return !prefix.isEmpty && prefix.allSatisfy(\.isNumber)
    }

    private static func stripOrderedPrefix(_ s: String) -> String {
        guard let dotRange = s.range(of: ". ") else { return s }
        return String(s[dotRange.upperBound...])
    }

    private static func parseImage(_ line: String) -> (alt: String, path: String)? {
        // ![alt](path)  — only a line that is *only* an image
        guard line.hasPrefix("!["), let bracketClose = line.firstIndex(of: "]"),
              line.index(after: bracketClose) < line.endIndex,
              line[line.index(after: bracketClose)] == "(",
              let parenClose = line.lastIndex(of: ")"),
              parenClose == line.index(before: line.endIndex)
        else { return nil }
        let alt = String(line[line.index(line.startIndex, offsetBy: 2)..<bracketClose])
        let path = String(line[line.index(bracketClose, offsetBy: 2)..<parenClose])
        return (alt, path)
    }
}
