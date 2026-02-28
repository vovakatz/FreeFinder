#!/usr/bin/env swift
import AppKit
import CoreGraphics

let outputDir = "BetterFinder/Assets.xcassets/AppIcon.appiconset"

struct IconSize {
    let name: String
    let pixels: Int
}

let sizes: [IconSize] = [
    IconSize(name: "icon_16x16.png", pixels: 16),
    IconSize(name: "icon_16x16@2x.png", pixels: 32),
    IconSize(name: "icon_32x32.png", pixels: 32),
    IconSize(name: "icon_32x32@2x.png", pixels: 64),
    IconSize(name: "icon_128x128.png", pixels: 128),
    IconSize(name: "icon_128x128@2x.png", pixels: 256),
    IconSize(name: "icon_256x256.png", pixels: 256),
    IconSize(name: "icon_256x256@2x.png", pixels: 512),
    IconSize(name: "icon_512x512.png", pixels: 512),
    IconSize(name: "icon_512x512@2x.png", pixels: 1024),
]

func drawIcon(size: Int) -> NSBitmapImageRep {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)

    let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = nsCtx
    let ctx = nsCtx.cgContext

    let cornerRadius = s * 0.22

    // --- Background: rounded rect with gradient ---
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                        cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradColors = [
        CGColor(red: 0.18, green: 0.45, blue: 0.82, alpha: 1.0),
        CGColor(red: 0.12, green: 0.32, blue: 0.70, alpha: 1.0),
        CGColor(red: 0.08, green: 0.22, blue: 0.55, alpha: 1.0),
    ]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradColors as CFArray, locations: [0, 0.5, 1]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])
    }

    // --- Subtle inner shadow / border ---
    ctx.resetClip()
    ctx.addPath(bgPath)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
    ctx.setLineWidth(s * 0.01)
    ctx.strokePath()

    // --- Folder body ---
    let folderX = s * 0.15
    let folderY = s * 0.20
    let folderW = s * 0.55
    let folderH = s * 0.45
    let tabW = s * 0.22
    let tabH = s * 0.08
    let fr = s * 0.04 // folder corner radius

    // Folder back (with tab)
    let folderBack = CGMutablePath()
    folderBack.move(to: CGPoint(x: folderX + fr, y: folderY + folderH + tabH))
    folderBack.addLine(to: CGPoint(x: folderX + tabW - fr, y: folderY + folderH + tabH))
    folderBack.addQuadCurve(to: CGPoint(x: folderX + tabW, y: folderY + folderH + tabH - fr),
                            control: CGPoint(x: folderX + tabW, y: folderY + folderH + tabH))
    folderBack.addLine(to: CGPoint(x: folderX + tabW, y: folderY + folderH))
    folderBack.addLine(to: CGPoint(x: folderX + folderW - fr, y: folderY + folderH))
    folderBack.addQuadCurve(to: CGPoint(x: folderX + folderW, y: folderY + folderH - fr),
                            control: CGPoint(x: folderX + folderW, y: folderY + folderH))
    folderBack.addLine(to: CGPoint(x: folderX + folderW, y: folderY + fr))
    folderBack.addQuadCurve(to: CGPoint(x: folderX + folderW - fr, y: folderY),
                            control: CGPoint(x: folderX + folderW, y: folderY))
    folderBack.addLine(to: CGPoint(x: folderX + fr, y: folderY))
    folderBack.addQuadCurve(to: CGPoint(x: folderX, y: folderY + fr),
                            control: CGPoint(x: folderX, y: folderY))
    folderBack.addLine(to: CGPoint(x: folderX, y: folderY + folderH + tabH - fr))
    folderBack.addQuadCurve(to: CGPoint(x: folderX + fr, y: folderY + folderH + tabH),
                            control: CGPoint(x: folderX, y: folderY + folderH + tabH))
    folderBack.closeSubpath()

    ctx.addPath(folderBack)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.90))
    ctx.fillPath()

    // Folder front (slightly offset, giving depth)
    let frontY = folderY - s * 0.02
    let frontH = folderH * 0.78
    let frontPath = CGPath(roundedRect: CGRect(x: folderX, y: frontY, width: folderW, height: frontH),
                           cornerWidth: fr, cornerHeight: fr, transform: nil)
    ctx.addPath(frontPath)
    ctx.setFillColor(CGColor(red: 0.92, green: 0.94, blue: 0.98, alpha: 0.95))
    ctx.fillPath()

    // --- Magnifying glass ---
    let glassR = s * 0.16
    let glassCX = s * 0.62
    let glassCY = s * 0.32
    let glassLineW = s * 0.035

    // Glass circle
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.setLineWidth(glassLineW)
    ctx.addEllipse(in: CGRect(x: glassCX - glassR, y: glassCY - glassR,
                              width: glassR * 2, height: glassR * 2))
    ctx.strokePath()

    // Glass fill (slight tint)
    ctx.addEllipse(in: CGRect(x: glassCX - glassR, y: glassCY - glassR,
                              width: glassR * 2, height: glassR * 2))
    ctx.setFillColor(CGColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.25))
    ctx.fillPath()

    // Handle
    let handleAngle = -CGFloat.pi / 4
    let handleStart = CGPoint(x: glassCX + (glassR + glassLineW * 0.3) * cos(handleAngle),
                              y: glassCY + (glassR + glassLineW * 0.3) * sin(handleAngle))
    let handleLen = s * 0.14
    let handleEnd = CGPoint(x: handleStart.x + handleLen * cos(handleAngle),
                            y: handleStart.y + handleLen * sin(handleAngle))

    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.setLineWidth(glassLineW * 1.3)
    ctx.setLineCap(.round)
    ctx.move(to: handleStart)
    ctx.addLine(to: handleEnd)
    ctx.strokePath()

    // --- Subtle highlight on top ---
    let highlightPath = CGMutablePath()
    highlightPath.addRoundedRect(in: CGRect(x: s * 0.05, y: s * 0.55, width: s * 0.9, height: s * 0.42),
                                  cornerWidth: cornerRadius * 0.8, cornerHeight: cornerRadius * 0.8)
    ctx.addPath(highlightPath)
    ctx.clip()
    let highlightColors = [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.12),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.0),
    ]
    if let hlGrad = CGGradient(colorsSpace: colorSpace, colors: highlightColors as CFArray, locations: [0, 1]) {
        ctx.drawLinearGradient(hlGrad, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: s * 0.55), options: [])
    }

    NSGraphicsContext.current = nil
    return rep
}

// Generate all sizes
for iconSize in sizes {
    let rep = drawIcon(size: iconSize.pixels)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(iconSize.name)")
        continue
    }
    let path = "\(outputDir)/\(iconSize.name)"
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("Generated \(iconSize.name) (\(iconSize.pixels)px)")
    } catch {
        print("Failed to write \(iconSize.name): \(error)")
    }
}

// Update Contents.json
let contentsJSON = """
{
  "images" : [
    { "filename" : "icon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

try! contentsJSON.write(toFile: "\(outputDir)/Contents.json", atomically: true, encoding: .utf8)
print("Updated Contents.json")
