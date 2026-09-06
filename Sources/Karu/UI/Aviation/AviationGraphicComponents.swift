import SwiftUI
import KaruCore

/// Luminous Flight Progress Slider Track — Direction A Monochrome Edition.
/// High-contrast crisp white slider capsule on recessed obsidian track with jet black airplane glyph.
public struct LuminousSliderTrackView: View {
    public var progress: Double
    public var state: TransitState
    public var remainingText: String
    public var onDragChanged: ((Double) -> Void)?
    public var onDragEnded: ((Double) -> Void)?

    public init(
        progress: Double,
        state: TransitState = .cruising,
        remainingText: String = "-25M 00S",
        onDragChanged: ((Double) -> Void)? = nil,
        onDragEnded: ((Double) -> Void)? = nil
    ) {
        self.progress = max(0.0, min(1.0, progress))
        self.state = state
        self.remainingText = remainingText
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color(hex: 0xE4E4E7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var body: some View {
        GeometryReader { geo in
            let totalWidth: CGFloat = geo.size.width
            let trackHeight: CGFloat = 28
            let minPillWidth: CGFloat = 46
            let activeWidth: CGFloat = max(minPillWidth, totalWidth * CGFloat(progress))

            ZStack(alignment: .leading) {
                // 1. Recessed Dark Groove Track (Anti-Aliased Obsidian Capsule)
                Capsule(style: .continuous)
                    .fill(Color(hex: 0x121216))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5, antialiased: true)
                    )

                // 2. Remaining Time Countdown Label on the right
                HStack {
                    Spacer()
                    Text(remainingText)
                        .font(KaruTheme.sliderCountdown)
                        .foregroundStyle(KaruTheme.textMuted)
                        .padding(.trailing, 12)
                }

                // 3. Ambient White Glow Spotlight beneath the active capsule (GPU-composited shadow)
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: activeWidth, height: trackHeight)
                    .shadow(color: Color.white.opacity(0.35), radius: 6, x: 0, y: 0)
                    .allowsHitTesting(false)

                // 4. Solid Crisp White Slider Capsule with Jet Black Airplane Glyph
                ZStack(alignment: .trailing) {
                    Capsule(style: .continuous)
                        .fill(accentGradient)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5, antialiased: true)
                        )
                        .shadow(color: Color.white.opacity(0.3), radius: 3, x: 0, y: 1)

                    // Jet Black Airplane Icon inside the white head of the capsule
                    Image(systemName: "airplane")
                        .font(.system(size: 11.5, weight: .black))
                        .foregroundStyle(Color.black)
                        .rotationEffect(.degrees(0))
                        .padding(.trailing, 9)
                }
                .frame(width: activeWidth, height: trackHeight - 4)
                .clipShape(Capsule(style: .continuous), style: FillStyle(antialiased: true))
                .padding(.leading, 2)
            }
            .frame(height: trackHeight)
            .clipShape(Capsule(style: .continuous), style: FillStyle(antialiased: true))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let frac: Double = max(0.0, min(1.0, Double(value.location.x / totalWidth)))
                        onDragChanged?(frac)
                    }
                    .onEnded { value in
                        let frac: Double = max(0.0, min(1.0, Double(value.location.x / totalWidth)))
                        onDragEnded?(frac)
                    }
            )
        }
        .frame(height: 28)
    }
}

/// Inset Recessed Pod for Flight ETA, Timezone, and Next Meal/Break Event.
public struct AvionicsInsetPodView: View {
    public var etaText: String
    public var timezoneText: String
    public var alertBadgeText: String
    public var onToggleTimezone: (() -> Void)?

    public init(
        etaText: String = "ETA 2:15 PM",
        timezoneText: String = "Tokyo Time",
        alertBadgeText: String = "DINNER IN 2:34H",
        onToggleTimezone: (() -> Void)? = nil
    ) {
        self.etaText = etaText
        self.timezoneText = timezoneText
        self.alertBadgeText = alertBadgeText
        self.onToggleTimezone = onToggleTimezone
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Row 1: ETA + Swap Icon
            HStack(spacing: 3) {
                Text(etaText)
                    .font(KaruTheme.etaValue)
                    .foregroundStyle(KaruTheme.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 2)

                Button {
                    onToggleTimezone?()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(KaruTheme.textPrimary)
                        .padding(3.5)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            // Row 2: Timezone label
            Text(timezoneText)
                .font(KaruTheme.etaSubtext)
                .foregroundStyle(KaruTheme.textMuted)

            // Row 3: High-Contrast Monochrome Event Highlight
            Text(alertBadgeText.uppercased())
                .font(KaruTheme.mealBadge)
                .foregroundStyle(KaruTheme.textPrimary)
                .tracking(0.3)
                .padding(.top, 0.5)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: KaruTheme.radiusPod, style: .continuous)
                .fill(KaruTheme.recessedTray)
                .overlay(
                    RoundedRectangle(cornerRadius: KaruTheme.radiusPod, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5, antialiased: true)
                )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: KaruTheme.radiusPod, style: .continuous),
            style: FillStyle(antialiased: true)
        )
    }
}

/// Geometric Ticket Shape with curved rounded corners and physical semicircular cutout notches on left and right edges.
public struct TicketShape: Shape {
    public var cornerRadius: CGFloat
    public var notchRadius: CGFloat
    public var notchY: CGFloat?
    public var notchYRatio: CGFloat

    public init(
        cornerRadius: CGFloat = 20,
        notchRadius: CGFloat = 9,
        notchY: CGFloat? = nil,
        notchYRatio: CGFloat = 0.69
    ) {
        self.cornerRadius = cornerRadius
        self.notchRadius = notchRadius
        self.notchY = notchY
        self.notchYRatio = notchYRatio
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let cy = notchY ?? (rect.height * notchYRatio)
        let cr = cornerRadius
        let nr = notchRadius

        // 1. Top edge
        path.move(to: CGPoint(x: rect.minX + cr, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cr, y: rect.minY))

        // 2. Top-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - cr, y: rect.minY + cr),
            radius: cr,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // 3. Right edge down to notch
        path.addLine(to: CGPoint(x: rect.maxX, y: cy - nr))

        // 4. Right semicircular inward notch
        path.addArc(
            center: CGPoint(x: rect.maxX, y: cy),
            radius: nr,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: true
        )

        // 5. Right edge down to bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cr))

        // 6. Bottom-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - cr, y: rect.maxY - cr),
            radius: cr,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // 7. Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + cr, y: rect.maxY))

        // 8. Bottom-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + cr, y: rect.maxY - cr),
            radius: cr,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // 9. Left edge up to notch
        path.addLine(to: CGPoint(x: rect.minX, y: cy + nr))

        // 10. Left semicircular inward notch
        path.addArc(
            center: CGPoint(x: rect.minX, y: cy),
            radius: nr,
            startAngle: .degrees(90),
            endAngle: .degrees(-90),
            clockwise: true
        )

        // 11. Left edge up to top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cr))

        // 12. Top-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + cr, y: rect.minY + cr),
            radius: cr,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}

/// Dotted World Map Silhouette Graphic.
public struct DottedWorldMapView: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let cols = 36
            let rows = 18
            let stepX = size.width / CGFloat(cols)
            let stepY = size.height / CGFloat(rows)

            for c in 0..<cols {
                for r in 0..<rows {
                    let normX = Double(c) / Double(cols)
                    let normY = Double(r) / Double(rows)

                    if isLandMass(x: normX, y: normY) {
                        let dotRect = CGRect(
                            x: CGFloat(c) * stepX + stepX * 0.2,
                            y: CGFloat(r) * stepY + stepY * 0.2,
                            width: 2.2,
                            height: 2.2
                        )
                        context.fill(Path(ellipseIn: dotRect), with: .color(Color(hex: 0x475569)))
                    }
                }
            }
        }
    }

    private func isLandMass(x: Double, y: Double) -> Bool {
        // Americas
        if (x > 0.12 && x < 0.32 && y > 0.20 && y < 0.75) { return true }
        // Europe & Africa
        if (x > 0.44 && x < 0.60 && y > 0.15 && y < 0.78) { return true }
        // Asia
        if (x > 0.58 && x < 0.88 && y > 0.18 && y < 0.62) { return true }
        // Australia
        if (x > 0.78 && x < 0.92 && y > 0.65 && y < 0.85) { return true }
        return false
    }
}

/// Curved 2D PDF417 Boarding Pass Barcode Graphic.
public struct CurvedBarcodeView: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let barCount = 72
            let barWidth = w / CGFloat(barCount)

            for i in 0..<barCount {
                let x = CGFloat(i) * barWidth
                let isBlack = ((i * 37 + 13) % 7) != 0 && ((i * 19) % 5) != 0
                if isBlack {
                    let rect = CGRect(x: x, y: 0, width: barWidth * 0.8, height: h)
                    context.fill(Path(rect), with: .color(Color.black))
                }
            }
        }
    }
}

/// Ticket Perforation Dashed Line.
public struct TicketPerforationLine: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height / 2))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
        return path
    }
}
