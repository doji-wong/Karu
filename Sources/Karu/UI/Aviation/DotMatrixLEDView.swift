import SwiftUI
import KaruCore

/// Procedural 5x7 Dot-Matrix LED Typography & Flight Route Renderer — Direction A Monochrome.
/// Crisp white illuminated LED dots for airport IATA codes and route arrows.
public enum DotMatrixGlyphs {
    // 5 columns wide x 7 rows high bitmap patterns for uppercase letters & digits
    @inline(__always)
    public static func pattern(for char: Character) -> [UInt8] {
        switch char {
        case "A": return [0b0111110, 0b0001001, 0b0001001, 0b0001001, 0b0111110]
        case "B": return [0b1111111, 0b1001001, 0b1001001, 0b1001001, 0b0110110]
        case "C": return [0b0111110, 0b1000001, 0b1000001, 0b1000001, 0b0100010]
        case "D": return [0b1111111, 0b1000001, 0b1000001, 0b1000001, 0b0111110]
        case "E": return [0b1111111, 0b1001001, 0b1001001, 0b1001001, 0b1000001]
        case "F": return [0b1111111, 0b0001001, 0b0001001, 0b0001001, 0b0000001]
        case "G": return [0b0111110, 0b1000001, 0b1001001, 0b1001001, 0b0111010]
        case "H": return [0b1111111, 0b0001000, 0b0001000, 0b0001000, 0b1111111]
        case "I": return [0b1000001, 0b1000001, 0b1111111, 0b1000001, 0b1000001]
        case "J": return [0b0100000, 0b1000000, 0b1000001, 0b1000001, 0b0111111]
        case "K": return [0b1111111, 0b0001000, 0b0010100, 0b0100010, 0b1000001]
        case "L": return [0b1111111, 0b1000000, 0b1000000, 0b1000000, 0b1000000]
        case "M": return [0b1111111, 0b0000010, 0b0000100, 0b0000010, 0b1111111]
        case "N": return [0b1111111, 0b0000110, 0b0011000, 0b0110000, 0b1111111]
        case "O": return [0b0111110, 0b1000001, 0b1000001, 0b1000001, 0b0111110]
        case "P": return [0b1111111, 0b0001001, 0b0001001, 0b0001001, 0b0000110]
        case "Q": return [0b0111110, 0b1000001, 0b1010001, 0b0100001, 0b1011110]
        case "R": return [0b1111111, 0b0001001, 0b0011001, 0b0101001, 0b1000110]
        case "S": return [0b0100110, 0b1001001, 0b1001001, 0b1001001, 0b0110010]
        case "T": return [0b0000001, 0b0000001, 0b1111111, 0b0000001, 0b0000001]
        case "U": return [0b0111111, 0b1000000, 0b1000000, 0b1000000, 0b0111111]
        case "V": return [0b0011111, 0b0100000, 0b1000000, 0b0100000, 0b0011111]
        case "W": return [0b1111111, 0b0100000, 0b0011000, 0b0100000, 0b1111111]
        case "X": return [0b1100011, 0b0010100, 0b0001000, 0b0010100, 0b1100011]
        case "Y": return [0b0000111, 0b0001000, 0b1110000, 0b0001000, 0b0000111]
        case "Z": return [0b1100001, 0b1010001, 0b1001001, 0b1000101, 0b1000011]
        case "0": return [0b0111110, 0b1000001, 0b1000001, 0b1000001, 0b0111110]
        case "1": return [0b0000000, 0b1000010, 0b1111111, 0b1000000, 0b0000000]
        case "2": return [0b1100010, 0b1010001, 0b1001001, 0b1001001, 0b1000110]
        case "3": return [0b0100010, 0b1000001, 0b1001001, 0b1001001, 0b0110110]
        case "4": return [0b0011000, 0b0010100, 0b0010010, 0b1111111, 0b0010000]
        case "5": return [0b0100111, 0b1000101, 0b1000101, 0b1000101, 0b0111001]
        case "6": return [0b0111110, 0b1001001, 0b1001001, 0b1001001, 0b0110000]
        case "7": return [0b0000001, 0b1110001, 0b0001001, 0b0000101, 0b0000011]
        case "8": return [0b0110110, 0b1001001, 0b1001001, 0b1001001, 0b0110110]
        case "9": return [0b0000110, 0b1001001, 0b1001001, 0b1001001, 0b0111110]
        case "-": return [0b0001000, 0b0001000, 0b0001000, 0b0001000, 0b0001000]
        case ">": return [0b0001000, 0b0010100, 0b0100010, 0b1000001, 0b0000000]
        default:  return [0b0000000, 0b0000000, 0b0000000, 0b0000000, 0b0000000]
        }
    }
}

/// Canvas-rendered 5x7 LED Dot Matrix Text string with subpixel smooth circles.
public struct DotMatrixTextView: View {
    public var text: String
    public var dotSize: CGFloat
    public var dotSpacing: CGFloat
    public var activeColor: Color
    public var showPassiveBackground: Bool

    public init(
        text: String,
        dotSize: CGFloat = 2.1,
        dotSpacing: CGFloat = 1.0,
        activeColor: Color = .white,
        showPassiveBackground: Bool = false
    ) {
        self.text = text.uppercased()
        self.dotSize = dotSize
        self.dotSpacing = dotSpacing
        self.activeColor = activeColor
        self.showPassiveBackground = showPassiveBackground
    }

    private let rows = 7
    private let colsPerChar = 5
    private let charGapCols = 1

    public var body: some View {
        let chars = Array(text)
        let totalCols = max(1, chars.count * colsPerChar + max(0, chars.count - 1) * charGapCols)
        let totalWidth = CGFloat(totalCols) * dotSize + CGFloat(totalCols - 1) * dotSpacing
        let totalHeight = CGFloat(rows) * dotSize + CGFloat(rows - 1) * dotSpacing

        Canvas { context, size in
            var colOffset = 0
            for char in chars {
                let bitmap = DotMatrixGlyphs.pattern(for: char)
                for (colIndex, columnByte) in bitmap.enumerated() {
                    let c = colOffset + colIndex
                    for r in 0..<rows {
                        let isLit = (columnByte & (1 << r)) != 0
                        let x = CGFloat(c) * (dotSize + dotSpacing)
                        let y = CGFloat(r) * (dotSize + dotSpacing)
                        let dotRect = CGRect(x: x, y: y, width: dotSize, height: dotSize)

                        if isLit {
                            context.fill(Path(ellipseIn: dotRect), with: .color(activeColor))
                        } else if showPassiveBackground {
                            context.fill(Path(ellipseIn: dotRect), with: .color(KaruTheme.dotMatrixPassive))
                        }
                    }
                }
                colOffset += colsPerChar + charGapCols
            }
        }
        .frame(width: totalWidth, height: totalHeight)
    }
}

/// Glowing Right Arrow Icon (➔) made of Dot Matrix Points pointing to the right — Pure Crisp White.
public struct DotMatrixArrowView: View {
    public var color: Color
    public var dotSize: CGFloat
    public var dotSpacing: CGFloat

    public init(
        color: Color = .white,
        dotSize: CGFloat = 2.1,
        dotSpacing: CGFloat = 1.0
    ) {
        self.color = color
        self.dotSize = dotSize
        self.dotSpacing = dotSpacing
    }

    public var body: some View {
        // True right-pointing arrow: shaft on left (cols 0, 1), arrowhead converging to tip on right (col 5)
        let arrowCols: [UInt8] = [
            0b0001000,
            0b0001000,
            0b1001001,
            0b0101010,
            0b0011100,
            0b0001000
        ]
        
        let width = CGFloat(6) * dotSize + CGFloat(5) * dotSpacing
        let height = CGFloat(7) * dotSize + CGFloat(6) * dotSpacing

        Canvas { context, _ in
            for (c, colByte) in arrowCols.enumerated() {
                for r in 0..<7 {
                    let isLit = (colByte & (1 << r)) != 0
                    if isLit {
                        let x = CGFloat(c) * (dotSize + dotSpacing)
                        let y = CGFloat(r) * (dotSize + dotSpacing)
                        let dotRect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                        context.fill(Path(ellipseIn: dotRect), with: .color(color))
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .shadow(color: color.opacity(0.4), radius: 2)
    }
}

/// Subtle Ambient Dot Grid Mesh Overlay for flight card backdrops.
public struct AmbientDotGridBackground: View {
    public init() {}

    public var body: some View {
        EmptyView()
    }
}
