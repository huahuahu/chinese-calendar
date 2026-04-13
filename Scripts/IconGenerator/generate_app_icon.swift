import AppKit

struct IconSpec {
    let filename: String
    let points: CGFloat
    let scale: CGFloat

    var pixels: Int {
        Int((points * scale).rounded())
    }
}

let outputDirectory = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst()
        .first ?? "./Apps/Shared/Resources/Assets.xcassets/AppIcon.appiconset",
    isDirectory: true
)
let fileManager = FileManager.default

try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let specs: [IconSpec] = [
    .init(filename: "icon-20@2x.png", points: 20, scale: 2),
    .init(filename: "icon-20@3x.png", points: 20, scale: 3),
    .init(filename: "icon-29@2x.png", points: 29, scale: 2),
    .init(filename: "icon-29@3x.png", points: 29, scale: 3),
    .init(filename: "icon-40@2x.png", points: 40, scale: 2),
    .init(filename: "icon-40@3x.png", points: 40, scale: 3),
    .init(filename: "icon-60@2x.png", points: 60, scale: 2),
    .init(filename: "icon-60@3x.png", points: 60, scale: 3),
    .init(filename: "icon-ipad-20.png", points: 20, scale: 1),
    .init(filename: "icon-ipad-20@2x.png", points: 20, scale: 2),
    .init(filename: "icon-ipad-29.png", points: 29, scale: 1),
    .init(filename: "icon-ipad-29@2x.png", points: 29, scale: 2),
    .init(filename: "icon-ipad-40.png", points: 40, scale: 1),
    .init(filename: "icon-ipad-40@2x.png", points: 40, scale: 2),
    .init(filename: "icon-ipad-76.png", points: 76, scale: 1),
    .init(filename: "icon-ipad-76@2x.png", points: 76, scale: 2),
    .init(filename: "icon-ipad-83.5@2x.png", points: 83.5, scale: 2),
    .init(filename: "icon-mac-16.png", points: 16, scale: 1),
    .init(filename: "icon-mac-16@2x.png", points: 16, scale: 2),
    .init(filename: "icon-mac-32.png", points: 32, scale: 1),
    .init(filename: "icon-mac-32@2x.png", points: 32, scale: 2),
    .init(filename: "icon-mac-128.png", points: 128, scale: 1),
    .init(filename: "icon-mac-128@2x.png", points: 128, scale: 2),
    .init(filename: "icon-mac-256.png", points: 256, scale: 1),
    .init(filename: "icon-mac-256@2x.png", points: 256, scale: 2),
    .init(filename: "icon-mac-512.png", points: 512, scale: 1),
    .init(filename: "icon-mac-512@2x.png", points: 512, scale: 2),
    .init(filename: "icon-ios-marketing.png", points: 1024, scale: 1)
]

func makeColor(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    let red = CGFloat((hex >> 16) & 0xFF) / 255
    let green = CGFloat((hex >> 8) & 0xFF) / 255
    let blue = CGFloat(hex & 0xFF) / 255
    return NSColor(red: red, green: green, blue: blue, alpha: alpha)
}

func roundedRectPath(in rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        for index in 0 ..< elementCount {
            switch element(at: index, associatedPoints: &points) {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                break
            }
        }
        return path
    }
}

func stroke(_ points: [CGPoint], width: CGFloat, color: NSColor, alpha: CGFloat = 1) {
    let path = NSBezierPath()
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.lineWidth = width
    if let first = points.first {
        path.move(to: first)
        for point in points.dropFirst() {
            path.line(to: point)
        }
    }
    color.withAlphaComponent(alpha).setStroke()
    path.stroke()
}

func fillCircle(_ rect: CGRect, color: NSColor, alpha: CGFloat = 1) {
    color.withAlphaComponent(alpha).setFill()
    NSBezierPath(ovalIn: rect).fill()
}

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let pixelSize = Int(size.rounded())
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let cgContext = CGContext(
              data: nil,
              width: pixelSize,
              height: pixelSize,
              bitsPerComponent: 8,
              bytesPerRow: 0,
              space: colorSpace,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          )
    else {
        fatalError("Unable to allocate bitmap for size \(size)")
    }

    cgContext.setAllowsAntialiasing(true)
    cgContext.setShouldAntialias(true)
    cgContext.interpolationQuality = .high

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(cgContext: cgContext, flipped: false)
    NSGraphicsContext.current = context

    let canvas = CGRect(x: 0, y: 0, width: size, height: size)
    let inset = size * 0.035
    let tileRect = canvas.insetBy(dx: inset, dy: inset)
    let tilePath = roundedRectPath(in: tileRect, radius: size * 0.23)
    tilePath.addClip()

    let baseGradient = NSGradient(colors: [
        makeColor(0x8F1218),
        makeColor(0xB11A23),
        makeColor(0xD4452A)
    ])!
    baseGradient.draw(in: tilePath, angle: -55)

    let glowRect = CGRect(x: size * 0.06, y: size * 0.1, width: size * 0.88, height: size * 0.88)
    let glowGradient = NSGradient(colors: [
        makeColor(0xF8B45A, alpha: 0.0),
        makeColor(0xF7C866, alpha: 0.18),
        makeColor(0xFFF2D0, alpha: 0.0)
    ])!
    glowGradient.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: NSPoint(x: 0.15, y: 0.3))

    let moonRect = CGRect(x: size * 0.58, y: size * 0.58, width: size * 0.24, height: size * 0.24)
    fillCircle(moonRect, color: makeColor(0xF6D37A))
    fillCircle(moonRect.offsetBy(dx: size * 0.03, dy: size * 0.005), color: makeColor(0xB11A23), alpha: 0.18)

    let sprinkleColor = makeColor(0xF7D98A)
    for (x, y, r, a) in [
        (0.20, 0.78, 0.010, 0.30),
        (0.30, 0.70, 0.008, 0.24),
        (0.78, 0.32, 0.012, 0.24),
        (0.16, 0.28, 0.009, 0.20),
        (0.70, 0.82, 0.006, 0.28)
    ] {
        fillCircle(
            CGRect(
                x: size * CGFloat(x) - size * CGFloat(r),
                y: size * CGFloat(y) - size * CGFloat(r),
                width: size * CGFloat(r * 2),
                height: size * CGFloat(r * 2)
            ),
            color: sprinkleColor,
            alpha: CGFloat(a)
        )
    }

    let paperRect = CGRect(x: size * 0.19, y: size * 0.17, width: size * 0.56, height: size * 0.60)
    let paperShadow = roundedRectPath(in: paperRect.offsetBy(dx: size * 0.015, dy: -size * 0.02), radius: size * 0.12)
    makeColor(0x5A0C12, alpha: 0.22).setFill()
    paperShadow.fill()

    let paperPath = roundedRectPath(in: paperRect, radius: size * 0.12)
    let paperGradient = NSGradient(colors: [makeColor(0xFFF9EB), makeColor(0xF3E1BE)])!
    paperGradient.draw(in: paperPath, angle: -90)

    let headerRect = CGRect(
        x: paperRect.minX,
        y: paperRect.maxY - size * 0.145,
        width: paperRect.width,
        height: size * 0.145
    )
    let headerPath = roundedRectPath(in: headerRect, radius: size * 0.12)
    let headerGradient = NSGradient(colors: [makeColor(0xC7392E), makeColor(0x9E1F1E)])!
    headerGradient.draw(in: headerPath, angle: -90)

    let ringY = headerRect.maxY - size * 0.03
    fillCircle(
        CGRect(x: paperRect.minX + size * 0.10, y: ringY, width: size * 0.045, height: size * 0.045),
        color: makeColor(0xF5D575)
    )
    fillCircle(
        CGRect(x: paperRect.maxX - size * 0.145, y: ringY, width: size * 0.045, height: size * 0.045),
        color: makeColor(0xF5D575)
    )

    makeColor(0xD5BA87, alpha: 0.35).setStroke()
    let linePath = NSBezierPath()
    linePath.lineWidth = max(1, size * 0.012)
    for row in 0 ..< 3 {
        let y = paperRect.minY + size * (0.16 + CGFloat(row) * 0.10)
        linePath.move(to: CGPoint(x: paperRect.minX + size * 0.09, y: y))
        linePath.line(to: CGPoint(x: paperRect.maxX - size * 0.09, y: y))
    }
    linePath.stroke()

    let charColor = makeColor(0xA01D1F)
    let shadowColor = NSColor.black
    let originX = paperRect.minX + size * 0.11
    let originY = paperRect.minY + size * 0.13
    let points: [[CGPoint]] = [
        [
            CGPoint(x: originX + size * 0.01, y: originY + size * 0.26),
            CGPoint(x: originX + size * 0.23, y: originY + size * 0.26)
        ],
        [
            CGPoint(x: originX + size * 0.11, y: originY + size * 0.08),
            CGPoint(x: originX + size * 0.11, y: originY + size * 0.33)
        ],
        [
            CGPoint(x: originX + size * 0.04, y: originY + size * 0.16),
            CGPoint(x: originX + size * 0.16, y: originY + size * 0.16)
        ],
        [
            CGPoint(x: originX + size * 0.23, y: originY + size * 0.29),
            CGPoint(x: originX + size * 0.31, y: originY + size * 0.16),
            CGPoint(x: originX + size * 0.22, y: originY + size * 0.02)
        ],
        [
            CGPoint(x: originX + size * 0.25, y: originY + size * 0.19),
            CGPoint(x: originX + size * 0.39, y: originY + size * 0.19)
        ],
        [
            CGPoint(x: originX + size * 0.33, y: originY + size * 0.08),
            CGPoint(x: originX + size * 0.33, y: originY + size * 0.29)
        ],
        [
            CGPoint(x: originX + size * 0.20, y: originY + size * 0.08),
            CGPoint(x: originX + size * 0.43, y: originY + size * 0.08)
        ],
        [
            CGPoint(x: originX + size * 0.24, y: originY + size * 0.02),
            CGPoint(x: originX + size * 0.40, y: originY + size * 0.02)
        ]
    ]
    let strokeWidth = size * 0.038
    for segment in points {
        let shadowPoints = segment.map { CGPoint(x: $0.x + size * 0.005, y: $0.y - size * 0.005) }
        stroke(shadowPoints, width: strokeWidth, color: shadowColor, alpha: 0.10)
        stroke(segment, width: strokeWidth, color: charColor)
    }

    let sealRect = CGRect(x: size * 0.68, y: size * 0.17, width: size * 0.12, height: size * 0.12)
    let sealPath = roundedRectPath(in: sealRect, radius: size * 0.03)
    makeColor(0xC3372E, alpha: 0.92).setFill()
    sealPath.fill()
    let sealInner = NSBezierPath()
    sealInner.lineWidth = max(1, size * 0.01)
    sealInner.move(to: CGPoint(x: sealRect.minX + size * 0.028, y: sealRect.midY))
    sealInner.line(to: CGPoint(x: sealRect.maxX - size * 0.028, y: sealRect.midY))
    sealInner.move(to: CGPoint(x: sealRect.midX, y: sealRect.minY + size * 0.028))
    sealInner.line(to: CGPoint(x: sealRect.midX, y: sealRect.maxY - size * 0.028))
    makeColor(0xF9E9C5).setStroke()
    sealInner.stroke()

    NSGraphicsContext.restoreGraphicsState()

    guard let cgImage = cgContext.makeImage() else {
        fatalError("Unable to extract image for size \(size)")
    }

    return NSBitmapImageRep(cgImage: cgImage)
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "IconGenerator",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG at \(url.path)"]
        )
    }
    try pngData.write(to: url)
}

for spec in specs {
    let image = drawIcon(size: CGFloat(spec.pixels))
    try writePNG(image, to: outputDirectory.appendingPathComponent(spec.filename))
    print("Generated \(spec.filename)")
}
