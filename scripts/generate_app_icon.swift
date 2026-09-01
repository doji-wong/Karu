#!/usr/bin/env swift
import Cocoa
import CoreGraphics

func drawKaruIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let center = CGPoint(x: size / 2, y: size / 2)
    let cornerRadius = size * 0.224 // Standard Apple macOS App Icon Squircle ratio

    // 1. Draw Rounded Squircle Base
    let clipPath = CGPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02),
                          cornerWidth: cornerRadius,
                          cornerHeight: cornerRadius,
                          transform: nil)
    ctx.addPath(clipPath)
    ctx.clip()

    // 2. Background Gradient (Deep Carbon Matte Avionics)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.11, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.03, green: 0.03, blue: 0.05, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient,
                               start: CGPoint(x: size / 2, y: size),
                               end: CGPoint(x: size / 2, y: 0),
                               options: [])
    }

    // 3. Subtle Outer Inner-Glow / Bevel
    ctx.saveGState()
    ctx.setStrokeColor(NSColor(calibratedRed: 0.25, green: 0.25, blue: 0.32, alpha: 0.6).cgColor)
    ctx.setLineWidth(size * 0.015)
    ctx.addPath(clipPath)
    ctx.strokePath()
    ctx.restoreGState()

    // 4. Concentric Radar & Pitch Horizon Rings
    ctx.saveGState()
    ctx.setStrokeColor(NSColor(calibratedRed: 0.0, green: 0.90, blue: 1.0, alpha: 0.18).cgColor)
    ctx.setLineWidth(size * 0.012)
    
    // Outer radar ring
    ctx.addArc(center: center, radius: size * 0.38, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()
    
    // Middle ring
    ctx.setLineDash(phase: 0, lengths: [size * 0.03, size * 0.02])
    ctx.addArc(center: center, radius: size * 0.28, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()
    ctx.restoreGState()

    // 5. Orange Pitch Scale Index Chevrons (Aviation Metaphor)
    ctx.saveGState()
    ctx.setStrokeColor(NSColor(calibratedRed: 1.0, green: 0.36, blue: 0.0, alpha: 0.85).cgColor)
    ctx.setLineWidth(size * 0.018)
    
    // Left pitch tick
    ctx.move(to: CGPoint(x: size * 0.18, y: center.y))
    ctx.addLine(to: CGPoint(x: size * 0.26, y: center.y))
    ctx.addLine(to: CGPoint(x: size * 0.26, y: center.y - size * 0.04))
    
    // Right pitch tick
    ctx.move(to: CGPoint(x: size * 0.82, y: center.y))
    ctx.addLine(to: CGPoint(x: size * 0.74, y: center.y))
    ctx.addLine(to: CGPoint(x: size * 0.74, y: center.y - size * 0.04))
    ctx.strokePath()
    ctx.restoreGState()

    // 6. Glowing Supersonic Aircraft Silhouette (A350F / Delta Needle)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.02),
                  blur: size * 0.08,
                  color: NSColor(calibratedRed: 0.0, green: 0.90, blue: 1.0, alpha: 0.7).cgColor)

    let jetPath = CGMutablePath()
    let nose = CGPoint(x: center.x, y: size * 0.78)
    let tail = CGPoint(x: center.x, y: size * 0.26)
    
    jetPath.move(to: nose) // Nose
    jetPath.addLine(to: CGPoint(x: center.x + size * 0.035, y: size * 0.62)) // Cockpit starboard
    jetPath.addLine(to: CGPoint(x: center.x + size * 0.34, y: size * 0.34))  // Right wing tip
    jetPath.addLine(to: CGPoint(x: center.x + size * 0.06, y: size * 0.38))  // Right wing root
    jetPath.addLine(to: CGPoint(x: center.x + size * 0.11, y: size * 0.22))  // Right tail tip
    jetPath.addLine(to: CGPoint(x: center.x + size * 0.02, y: tail.y))       // Right tail base
    jetPath.addLine(to: tail) // Tail center
    jetPath.addLine(to: CGPoint(x: center.x - size * 0.02, y: tail.y))       // Left tail base
    jetPath.addLine(to: CGPoint(x: center.x - size * 0.11, y: size * 0.22))  // Left tail tip
    jetPath.addLine(to: CGPoint(x: center.x - size * 0.06, y: size * 0.38))  // Left wing root
    jetPath.addLine(to: CGPoint(x: center.x - size * 0.34, y: size * 0.34))  // Left wing tip
    jetPath.addLine(to: CGPoint(x: center.x - size * 0.035, y: size * 0.62)) // Cockpit port
    jetPath.closeSubpath()

    // Fill Jet with Titanium White / Ice Cyan Gradient
    ctx.addPath(jetPath)
    ctx.clip()

    let jetColors = [
        NSColor(calibratedRed: 0.95, green: 0.98, blue: 1.0, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.65, green: 0.85, blue: 0.95, alpha: 1.0).cgColor
    ] as CFArray
    if let jetGradient = CGGradient(colorsSpace: colorSpace, colors: jetColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(jetGradient,
                               start: nose,
                               end: tail,
                               options: [])
    }
    ctx.restoreGState()

    // 7. Supersonic Afterburner Glow Pulse
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: size * 0.06, color: NSColor(calibratedRed: 1.0, green: 0.36, blue: 0.0, alpha: 0.9).cgColor)
    ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.1, alpha: 0.95).cgColor)
    ctx.addEllipse(in: CGRect(x: center.x - size * 0.025, y: size * 0.23, width: size * 0.05, height: size * 0.05))
    ctx.fillPath()
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

func exportPNG(image: NSImage, targetURL: URL, size: CGFloat) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG for size \(size)")
        return
    }
    try? pngData.write(to: targetURL)
}

// MARK: - Main Execution
let fm = FileManager.default
let currentDir = URL(fileURLWithPath: fm.currentDirectoryPath)
let iconsetDir = currentDir.appendingPathComponent("Packaging/AppIcon.iconset")
let resourcesDir = currentDir.appendingPathComponent("Packaging/Resources")
let outputICNS = currentDir.appendingPathComponent("Packaging/AppIcon.icns")

try? fm.createDirectory(at: iconsetDir, withIntermediateDirectories: true)
try? fm.createDirectory(at: resourcesDir, withIntermediateDirectories: true)

let iconSpecs: [(name: String, size: CGFloat, scale: CGFloat)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

print("[IconGen] Generating Karu Avionics App Icon assets...")

for spec in iconSpecs {
    let pixelSize = spec.size * spec.scale
    let image = drawKaruIcon(size: pixelSize)
    let fileURL = iconsetDir.appendingPathComponent(spec.name)
    exportPNG(image: image, targetURL: fileURL, size: pixelSize)
}

// Convert iconset to .icns using iconutil
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", outputICNS.path]

do {
    try process.run()
    process.waitUntilExit()
    if process.terminationStatus == 0 {
        print("✅ [IconGen] Successfully generated: \(outputICNS.path)")
        // Also copy to Packaging/Resources/AppIcon.icns
        let resourceTarget = resourcesDir.appendingPathComponent("AppIcon.icns")
        try? fm.removeItem(at: resourceTarget)
        try? fm.copyItem(at: outputICNS, to: resourceTarget)
    } else {
        print("❌ [IconGen] iconutil failed with exit code \(process.terminationStatus)")
    }
} catch {
    print("❌ [IconGen] Error running iconutil: \(error)")
}
