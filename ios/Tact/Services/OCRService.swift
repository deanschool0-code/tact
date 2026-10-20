import UIKit
import Vision

/// Reads chat screenshots on the device with Apple's Vision framework. The image never leaves the phone.
enum OCRService {
    enum OCRError: LocalizedError {
        case noImage, noText
        var errorDescription: String? {
            switch self {
            case .noImage: return "Couldn't open that image."
            case .noText: return "Couldn't find any messages in that screenshot. Try a sharper one, or type it in."
            }
        }
    }

    struct Piece {
        let text: String
        let box: CGRect  // normalised, origin bottom-left (Vision coordinates)
    }

    /// Chat bubbles in reading order, with "me" for right-aligned bubbles and "them" for left-aligned ones.
    static func readChat(from image: UIImage) async throws -> [ChatLine] {
        let pieces = try await recognise(image)
        let lines = groupIntoBubbles(pieces.filter { !isNoise($0) })
        if lines.isEmpty { throw OCRError.noText }
        return lines
    }

    /// Plain text (for profiles and bios), top to bottom.
    static func readText(from image: UIImage) async throws -> String {
        let pieces = try await recognise(image).filter { !isNoise($0) }
        if pieces.isEmpty { throw OCRError.noText }
        return pieces.sorted { $0.box.maxY > $1.box.maxY }.map(\.text).joined(separator: "\n")
    }

    static func recognise(_ image: UIImage) async throws -> [Piece] {
        guard let cg = image.cgImage else { throw OCRError.noImage }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.automaticallyDetectsLanguage = true
                do {
                    try VNImageRequestHandler(cgImage: cg, orientation: orientation).perform([request])
                    let pieces = (request.results ?? []).compactMap { o -> Piece? in
                        guard let t = o.topCandidates(1).first?.string.trimmingCharacters(in: .whitespaces),
                              !t.isEmpty else { return nil }
                        return Piece(text: t, box: o.boundingBox)
                    }
                    cont.resume(returning: pieces)
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Heuristics (pure functions, easy to tune)

    private static let noisePatterns: [NSRegularExpression] = [
        "^\\d{1,2}[:.]\\d{2}(\\s?[AaPp]\\.?[Mm]\\.?)?$",                       // 9:41, 21:05, 9:41 PM
        "^(today|yesterday|hoy|ayer)\\b.*",                                    // date separators
        "^(mon|tue|wed|thu|fri|sat|sun|lun|mar|mié|jue|vie|sáb|dom)[a-zé]*\\.?(\\s.*)?$",
        "^(delivered|read|seen|sent|visto|entregado|leído)(\\s.*)?$",
        "^(imessage|text message|message|mensaje|type a message|send a message|escribe un mensaje|aa)$",
        "^\\d{1,3}%$", "^(lte|5g|4g|wi-?fi)$",
        "^(active now|online|en línea|typing\\.{0,3}|escribiendo\\.{0,3})$",
    ].compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }

    static func isNoise(_ p: Piece) -> Bool {
        let t = p.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= 1 { return true }
        // Very top of the screen = status bar; very bottom = the input bar.
        if p.box.minY > 0.955 || p.box.maxY < 0.035 { return true }
        // Centred text is the app's own (names, dates, "Messages are end-to-end encrypted"), not a bubble.
        if abs(p.box.midX - 0.5) < 0.06 && p.box.width < 0.5 { return true }
        let range = NSRange(t.startIndex..., in: t)
        return noisePatterns.contains { $0.firstMatch(in: t, range: range) != nil }
    }

    static func side(of box: CGRect) -> Side {
        // Right-aligned bubbles are the screenshot owner's. Wide centred text falls back to the midpoint.
        if box.minX > 0.28 { return .me }
        if box.maxX < 0.72 { return .them }
        return box.midX > 0.5 ? .me : .them
    }

    static func groupIntoBubbles(_ pieces: [Piece]) -> [ChatLine] {
        let sorted = pieces.sorted { $0.box.maxY > $1.box.maxY }  // top first
        var out: [ChatLine] = []
        var lastBox: CGRect?
        for p in sorted {
            let s = side(of: p.box)
            if let last = out.last, let lb = lastBox, last.from == s {
                let gap = lb.minY - p.box.maxY
                let lineHeight = max(p.box.height, lb.height)
                if gap < lineHeight * 0.9 {
                    out[out.count - 1].text += " " + p.text
                    lastBox = p.box
                    continue
                }
            }
            out.append(ChatLine(from: s, text: p.text))
            lastBox = p.box
        }
        return out
    }
}

extension CGImagePropertyOrientation {
    init(_ o: UIImage.Orientation) {
        switch o {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
