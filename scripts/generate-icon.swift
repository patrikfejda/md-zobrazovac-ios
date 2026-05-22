#!/usr/bin/env swift
import AppKit
import SwiftUI

@MainActor
func renderIcon(size: CGFloat) -> CGImage? {
    let icon = ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.180, green: 0.231, blue: 0.271),  // slate top
                Color(red: 0.290, green: 0.396, blue: 0.502),  // slate-blue bottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        // SF Symbol only — system fonts behave inconsistently inside a
        // headless ImageRenderer, but SF Symbols always render.
        Image(systemName: "doc.richtext")
            .resizable()
            .scaledToFit()
            .padding(size * 0.22)
            .foregroundStyle(Color(red: 0.97, green: 0.96, blue: 0.93))
    }
    .frame(width: size, height: size)

    let renderer = ImageRenderer(content: icon)
    renderer.scale = 1.0
    return renderer.cgImage
}

@MainActor
func run() throws {
    let outPath = CommandLine.arguments.dropFirst().first ?? "icon-1024.png"

    guard let cgImage = renderIcon(size: 1024) else {
        fputs("Failed to render CGImage\n", stderr)
        exit(1)
    }

    let bitmap = NSBitmapImageRep(cgImage: cgImage)
    bitmap.size = NSSize(width: 1024, height: 1024)
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fputs("Failed to encode PNG\n", stderr)
        exit(1)
    }

    try png.write(to: URL(fileURLWithPath: outPath))
    print("Wrote \(outPath) (\(png.count) bytes)")
}

try MainActor.assumeIsolated { try run() }
