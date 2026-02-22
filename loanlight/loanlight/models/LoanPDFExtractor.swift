import Vision
import PDFKit
import Foundation

// MARK: - Extracted Loan Data

struct ExtractedLoanData {
    var servicer: String = ""
    var totalBalance: String = ""
    var interestRate: String = ""
    var monthlyPayment: String = ""
    var loanType: String = ""
    var repaymentPlan: String = ""
    var loanStatus: String = ""
}

// MARK: - PDF Extractor
//
// PDFKit extracts label + value on the SAME line:
//   "TOTAL OUTSTANDING PRINCIPAL BALANCE $27,000.00"
//   "TOTAL MINIMUM MONTHLY PAYMENT $142.00"
//   "CURRENT REPAYMENT PLAN SAVE (Saving on a Valuable Education)"
//   "OVERALL LOAN STATUS In Repayment"
//   "Subsidized 2021 $3,500.00 $3,500.00 3.730% $34.00 Repayment"
//
// Every pattern below is matched to these exact formats.

class LoanPDFExtractor {

    static func extract(from url: URL, completion: @escaping (Result<ExtractedLoanData, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {

            // Try PDFKit first (digital PDFs)
            if let pdfDoc = PDFDocument(url: url) {
                let text = extractText(from: pdfDoc)
                if text.count > 100 {
                    let loan = parseFullText(text)
                    DispatchQueue.main.async { completion(.success(loan)) }
                    return
                }
            }

            // Fallback: Vision OCR (scanned PDFs)
            guard let cgPDF = CGPDFDocument(url as CFURL) else {
                DispatchQueue.main.async {
                    completion(.failure(ExtractionError.couldNotOpenPDF))
                }
                return
            }
            extractViaOCR(cgPDF: cgPDF) { loan in
                DispatchQueue.main.async { completion(.success(loan)) }
            }
        }
    }

    // MARK: - PDFKit Text Extraction

    private static func extractText(from doc: PDFDocument) -> String {
        var text = ""
        let pageCount = min(doc.pageCount, 5)
        for i in 0..<pageCount {
            guard let page = doc.page(at: i) else { continue }
            text += (page.string ?? "") + "\n"
        }
        return text
    }

    // MARK: - Main Parser

    private static func parseFullText(_ text: String) -> ExtractedLoanData {
        var loan = ExtractedLoanData()

        // ── 1. Servicer — appears in first 5 lines ────────────────────
        for line in text.components(separatedBy: .newlines).prefix(5) {
            for s in ["Aidvantage", "MOHELA", "Nelnet", "Navient", "Edfinancial",
                      "FedLoan", "Great Lakes", "OSLA", "Trellis", "ECMC"] {
                if line.contains(s) { loan.servicer = s; break }
            }
            if !loan.servicer.isEmpty { break }
        }

        // ── 2. Total Balance ──────────────────────────────────────────
        // Exact line: "TOTAL OUTSTANDING PRINCIPAL BALANCE $27,000.00"
        loan.totalBalance = captureAmount(
            pattern: #"TOTAL OUTSTANDING PRINCIPAL BALANCE\s+\$?([\d,]+\.\d{2})"#,
            in: text
        ) ?? captureAmount(
            pattern: #"TOTAL AMOUNT OWED\s+\$?([\d,]+\.\d{2})"#,
            in: text
        ) ?? ""

        // ── 3. Monthly Payment ────────────────────────────────────────
        // Exact line: "TOTAL MINIMUM MONTHLY PAYMENT $142.00"
        // For deferment PDFs the value is "$0.00 (In-School Deferment)" — skip $0
        loan.monthlyPayment = captureAmount(
            pattern: #"TOTAL MINIMUM MONTHLY PAYMENT\s+\$?([\d,]+\.\d{2})"#,
            in: text,
            skipZero: false   // keep $0.00 for deferment — caller can handle display
        ) ?? ""

        // ── 4. Repayment Plan ─────────────────────────────────────────
        // Exact line: "CURRENT REPAYMENT PLAN SAVE (Saving on a Valuable Education)"
        // Captures everything after the label to end of line
        if let raw = text.firstCapture(pattern: #"CURRENT REPAYMENT PLAN\s+([^\n]+)"#) {
            loan.repaymentPlan = normalizePlan(raw.trimmingCharacters(in: .whitespaces))
        } else if let raw = text.firstCapture(pattern: #"REPAYMENT PLAN\s+([^\n]+)"#) {
            loan.repaymentPlan = normalizePlan(raw.trimmingCharacters(in: .whitespaces))
        }

        // ── 5. Loan Status ────────────────────────────────────────────
        // Exact line: "OVERALL LOAN STATUS In Repayment"
        if let raw = text.firstCapture(pattern: #"OVERALL LOAN STATUS\s+([^\n]+)"#) {
            loan.loanStatus = raw.trimmingCharacters(in: .whitespaces)
        } else {
            loan.loanStatus = "In Repayment"
        }

        // ── 6. Interest Rate ──────────────────────────────────────────
        // Loan detail rows: "Subsidized 2021 $3,500.00 $3,500.00 3.730% $34.00 Repayment"
        // Pattern: two dollar amounts then X.XXX%
        // We collect ALL rates and pick the lowest (best rate for summary display)
        let ratePattern = #"\$[\d,]+\.\d{2}\s+(\d{1,2}\.\d{3})%"#
        if let allRates = allCaptures(pattern: ratePattern, in: text) {
            let doubles = allRates.compactMap { Double($0) }
            if let lowest = doubles.min() {
                loan.interestRate = String(format: "%.3f", lowest) + "%"
            }
        }
        // Fallback: any X.XXX% that isn't 100%
        if loan.interestRate.isEmpty {
            if let r = text.firstCapture(pattern: #"\b(\d{1,2}\.\d{3})%"#) {
                loan.interestRate = r + "%"
            }
        }

        // ── 7. Loan Type ──────────────────────────────────────────────
        // Loan rows start with just "Subsidized" or "Unsubsidized" or "PLUS"
        // because "Direct" is on the line above in the table
        // Full type strings also appear in the interest summary section
        let typeMap: [(String, String)] = [
            ("Direct Subsidized",   "Direct Subsidized"),
            ("Direct Unsubsidized", "Direct Unsubsidized"),
            ("Direct Grad PLUS",    "Direct Grad PLUS"),
            ("Grad PLUS",           "Grad PLUS"),
            ("Direct PLUS",         "Direct PLUS"),
            ("Parent PLUS",         "Parent PLUS"),
            ("Perkins",             "Perkins"),
        ]
        for (kw, label) in typeMap {
            if text.range(of: kw, options: .caseInsensitive) != nil {
                loan.loanType = label; break
            }
        }
        // If still empty, infer from row keywords
        if loan.loanType.isEmpty {
            if text.range(of: "Subsidized", options: .caseInsensitive) != nil {
                loan.loanType = "Direct Subsidized"
            } else if text.range(of: "Unsubsidized", options: .caseInsensitive) != nil {
                loan.loanType = "Direct Unsubsidized"
            } else if text.range(of: "PLUS", options: .caseInsensitive) != nil {
                loan.loanType = "Direct PLUS"
            }
        }

        // ── Servicer fallback ─────────────────────────────────────────
        if loan.servicer.isEmpty {
            for s in ["Aidvantage", "MOHELA", "Nelnet", "Navient", "Edfinancial",
                      "FedLoan", "Great Lakes", "OSLA", "Trellis", "ECMC"] {
                if text.range(of: s, options: .caseInsensitive) != nil {
                    loan.servicer = s; break
                }
            }
        }

        return loan
    }

    // MARK: - Helpers

    /// Captures a dollar amount from a regex, optionally skipping $0.00
    private static func captureAmount(pattern: String, in text: String, skipZero: Bool = true) -> String? {
        guard let m = text.firstCapture(pattern: pattern) else { return nil }
        let clean = m.replacingOccurrences(of: ",", with: "")
        if skipZero && (Double(clean) ?? 0) == 0 { return nil }
        return "$" + clean
    }

    /// Returns every capture group 1 match for a pattern across the whole text
    private static func allCaptures(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        guard !matches.isEmpty else { return nil }
        return matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[r])
        }
    }

    private static func normalizePlan(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("save")      { return "SAVE" }
        if lower.contains("repaye")    { return "REPAYE" }
        if lower.contains("paye")      { return "PAYE" }
        if lower.contains("ibr")       { return "IBR" }
        if lower.contains("icr")       { return "ICR" }
        if lower.contains("graduated") { return "Graduated" }
        if lower.contains("extended")  { return "Extended" }
        if lower.contains("standard")  { return "Standard" }
        if lower.contains("not yet")   { return "Not Yet Assigned" }
        return raw
    }

    // MARK: - Vision OCR Fallback

    private static func extractViaOCR(cgPDF: CGPDFDocument, completion: @escaping (ExtractedLoanData) -> Void) {
        var allText = ""
        let group = DispatchGroup()
        let pageCount = min(cgPDF.numberOfPages, 5)
        for i in 1...pageCount {
            guard let page = cgPDF.page(at: i),
                  let image = renderCGPage(page) else { continue }
            group.enter()
            recognizeText(in: image) { text in
                allText += text + "\n"
                group.leave()
            }
        }
        group.notify(queue: .global()) {
            completion(parseFullText(allText))
        }
    }

    private static func renderCGPage(_ page: CGPDFPage) -> UIImage? {
        let scale: CGFloat = 2.0
        let pageRect = page.getBoxRect(.mediaBox)
        let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let context = ctx.cgContext
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: 0, y: pageRect.height)
            context.scaleBy(x: 1, y: -1)
            context.drawPDFPage(page)
        }
    }

    private static func recognizeText(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else { completion(""); return }
        let request = VNRecognizeTextRequest { req, _ in
            let text = (req.results as? [VNRecognizedTextObservation])?
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n") ?? ""
            completion(text)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
    }
}

// MARK: - Supporting Types

struct RecognizedTextBlock {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

enum ExtractionError: LocalizedError {
    case couldNotOpenPDF
    var errorDescription: String? {
        "Could not open the PDF. Please make sure it's a valid loan statement."
    }
}

extension String {
    func firstCapture(pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = regex.firstMatch(
                in: self,
                range: NSRange(self.startIndex..., in: self)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: self)
        else { return nil }
        return String(self[range])
    }
}
