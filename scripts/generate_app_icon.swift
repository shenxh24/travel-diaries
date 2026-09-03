import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

// Warm paper-like ground. iOS applies the final corner mask.
NSColor(calibratedRed: 0.953, green: 0.918, blue: 0.847, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

// Quiet map contours behind the mark.
NSColor(calibratedRed: 0.36, green: 0.65, blue: 0.63, alpha: 0.16).setStroke()
for offset in [-80.0, 85.0] {
    let contour = NSBezierPath()
    contour.lineWidth = 34
    contour.lineCapStyle = .round
    contour.move(to: NSPoint(x: 110, y: 330 + offset))
    contour.curve(to: NSPoint(x: 914, y: 590 + offset),
                  controlPoint1: NSPoint(x: 330, y: 650 + offset),
                  controlPoint2: NSPoint(x: 680, y: 250 + offset))
    contour.stroke()
}

// Single, bold location pin silhouette.
let pin = NSBezierPath()
pin.move(to: NSPoint(x: 512, y: 148))
pin.curve(to: NSPoint(x: 270, y: 590),
          controlPoint1: NSPoint(x: 455, y: 245),
          controlPoint2: NSPoint(x: 270, y: 430))
pin.curve(to: NSPoint(x: 512, y: 842),
          controlPoint1: NSPoint(x: 270, y: 730),
          controlPoint2: NSPoint(x: 378, y: 842))
pin.curve(to: NSPoint(x: 754, y: 590),
          controlPoint1: NSPoint(x: 646, y: 842),
          controlPoint2: NSPoint(x: 754, y: 730))
pin.curve(to: NSPoint(x: 512, y: 148),
          controlPoint1: NSPoint(x: 754, y: 430),
          controlPoint2: NSPoint(x: 569, y: 245))
pin.close()
NSColor(calibratedRed: 0.055, green: 0.365, blue: 0.345, alpha: 1).setFill()
pin.fill()

// A small journey path inside the pin, ending in a footprint-like dot.
let journey = NSBezierPath()
journey.lineWidth = 38
journey.lineCapStyle = .round
journey.move(to: NSPoint(x: 425, y: 640))
journey.curve(to: NSPoint(x: 584, y: 464),
              controlPoint1: NSPoint(x: 585, y: 625),
              controlPoint2: NSPoint(x: 422, y: 492))
journey.curve(to: NSPoint(x: 525, y: 350),
              controlPoint1: NSPoint(x: 665, y: 422),
              controlPoint2: NSPoint(x: 606, y: 350))
NSColor(calibratedRed: 0.953, green: 0.918, blue: 0.847, alpha: 1).setStroke()
journey.stroke()

let endpoint = NSBezierPath(ovalIn: NSRect(x: 487, y: 312, width: 76, height: 76))
NSColor(calibratedRed: 0.953, green: 0.918, blue: 0.847, alpha: 1).setFill()
endpoint.fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to render icon")
}

let output = CommandLine.arguments.dropFirst().first ?? "AppIcon-1024.png"
try png.write(to: URL(fileURLWithPath: output), options: .atomic)

