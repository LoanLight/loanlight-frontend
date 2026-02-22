//
//  Offerletter.swift
//  loanlight
//
//  Created by Sruthy Mammen on 2/21/26.
//
import SwiftUI
import Vision
import CoreGraphics
internal import UniformTypeIdentifiers

// MARK: - Local extraction model (UI-only)

struct OfferLetterData {
    var annualSalary: String = ""
    var startDate: String = ""
    var employmentType: String = ""
    var jobTitle: String = ""
    var company: String = ""
    var location: String = ""

    /// State derived from location string (last 2-letter token), e.g. "New York, NY" → "NY"
    var stateCode: String {
        let parts = location.components(separatedBy: ",")
        return parts.last?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    /// Converts to the backend request model.
    /// Returns nil if salary or state cannot be parsed.
    func toJobOfferIn() -> JobOfferIn? {
        let salaryClean = annualSalary
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        guard let salary = Decimal(string: salaryClean), !stateCode.isEmpty else { return nil }
        return JobOfferIn(
            baseSalary: salary,
            bonus: nil,
            state: stateCode
        )
    }
}

// MARK: - Extractor

class OfferLetterExtractor {

    static func extract(from url: URL, completion: @escaping (Result<OfferLetterData, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgPDF = CGPDFDocument(url as CFURL) else {
                DispatchQueue.main.async {
                    completion(.failure(ExtractionError.couldNotOpenPDF))
                }
                return
            }

            var allText = ""
            let group = DispatchGroup()
            let pageCount = min(cgPDF.numberOfPages, 5)

            for i in 1...pageCount {
                guard let page = cgPDF.page(at: i),
                      let image = renderPage(page) else { continue }
                group.enter()
                recognizeText(in: image) { text in
                    allText += text + "\n"
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(.success(parse(allText)))
            }
        }
    }

    private static func renderPage(_ page: CGPDFPage) -> UIImage? {
        let scale: CGFloat = 2.0
        let rect = page.getBoxRect(.mediaBox)
        let size = CGSize(width: rect.width * scale, height: rect.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let context = ctx.cgContext
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: 0, y: rect.height)
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

    private static func parse(_ text: String) -> OfferLetterData {
        var data = OfferLetterData()

        // ── Salary ──
        let salaryPatterns = [
            #"[Aa]nnual\s+[Ss]alary[:\s]+\$?([\d,]+\.?\d*)"#,
            #"[Bb]ase\s+[Ss]alary[:\s]+\$?([\d,]+\.?\d*)"#,
            #"[Ss]tarting\s+[Ss]alary[:\s]+\$?([\d,]+\.?\d*)"#,
            #"[Cc]ompensation[:\s]+\$?([\d,]+\.?\d*)"#,
            #"[Ss]alary[:\s]+\$?([\d,]+\.?\d*)"#,
            #"\$\s*([\d,]+)\s+(?:per year|annually|\/year|\/yr)"#,
        ]
        for p in salaryPatterns {
            if let match = text.firstCapture(pattern: p) {
                let clean = match.replacingOccurrences(of: ",", with: "")
                if let val = Double(clean), val > 10_000 {
                    data.annualSalary = "$\(Int(val).formatted())"
                    break
                }
            }
        }

        // ── Start Date ──
        let datePatterns = [
            #"[Ss]tart\s+[Dd]ate[:\s]+([A-Za-z]+ \d{1,2},?\s+\d{4})"#,
            #"[Cc]ommencement\s+[Dd]ate[:\s]+([A-Za-z]+ \d{1,2},?\s+\d{4})"#,
            #"[Ff]irst\s+[Dd]ay[:\s]+([A-Za-z]+ \d{1,2},?\s+\d{4})"#,
            #"[Ss]tart(?:ing)?\s+on\s+([A-Za-z]+ \d{1,2},?\s+\d{4})"#,
            #"[Ss]tart\s+[Dd]ate[:\s]+(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4})"#,
        ]
        for p in datePatterns {
            if let match = text.firstCapture(pattern: p) {
                data.startDate = match.trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        // ── Employment Type ──
        let lower = text.lowercased()
        if lower.contains("full-time") || lower.contains("full time") {
            data.employmentType = "Full-Time / W-2"
        } else if lower.contains("part-time") || lower.contains("part time") {
            data.employmentType = "Part-Time"
        } else if lower.contains("contractor") || lower.contains("contract") || lower.contains("1099") {
            data.employmentType = "Contract / 1099"
        } else if lower.contains("intern") {
            data.employmentType = "Internship"
        } else {
            data.employmentType = "Full-Time / W-2"
        }

        // ── Job Title ──
        let titlePatterns = [
            #"[Pp]osition[:\s]+([A-Za-z\s]+(?:Engineer|Manager|Designer|Developer|Analyst|Director|Associate|Coordinator|Specialist|Consultant)[^\n]*)"#,
            #"[Tt]itle[:\s]+([A-Za-z\s]+(?:Engineer|Manager|Designer|Developer|Analyst|Director|Associate|Coordinator|Specialist|Consultant)[^\n]*)"#,
            #"[Rr]ole[:\s]+([A-Za-z\s]+(?:Engineer|Manager|Designer|Developer|Analyst|Director|Associate|Coordinator|Specialist|Consultant)[^\n]*)"#,
        ]
        for p in titlePatterns {
            if let match = text.firstCapture(pattern: p) {
                data.jobTitle = match.trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        // ── Company (first non-salutation line) ──
        for line in text.components(separatedBy: .newlines).prefix(3) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 3 && trimmed.count < 60
                && !trimmed.hasPrefix("Dear")
                && !trimmed.hasPrefix("To:") {
                data.company = trimmed
                break
            }
        }

        // ── Location ──
        let locationPatterns = [
            #"[Ll]ocation[:\s]+([A-Za-z\s,]+(?:,\s*[A-Z]{2})?)"#,
            #"[Oo]ffice[:\s]+([A-Za-z\s,]+(?:,\s*[A-Z]{2})?)"#,
            #"[Ww]ork(?:ing)?\s+[Ll]ocation[:\s]+([A-Za-z\s,]+(?:,\s*[A-Z]{2})?)"#,
            #"[Bb]ased\s+in[:\s]+([A-Za-z\s,]+(?:,\s*[A-Z]{2})?)"#,
        ]
        for p in locationPatterns {
            if let match = text.firstCapture(pattern: p) {
                data.location = match.trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }

        return data
    }
}

// MARK: - Offer Letter View

struct OfferLetterView: View {

    var currentStep: Int = 3
    var totalSteps: Int = 6
    /// Passes a validated JobOfferIn to the parent; nil if parsing failed.
    var onContinue: (JobOfferIn?) -> Void = { _ in }

    @State private var offerData = OfferLetterData()
    @State private var showFilePicker = false
    @State private var isExtracting = false
    @State private var hasUploaded = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            Color.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Progress Bar ──
                HStack(spacing: 4) {
                    ForEach(1...totalSteps, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: 3)
                            .foregroundColor(step <= currentStep ? .primary : Color(.systemGray5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Step Pill ──
                        HStack(spacing: 6) {
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.primary)
                            Text("STEP \(currentStep) OF \(totalSteps)")
                                .font(AppFont.chip)
                                .foregroundColor(.primary)
                                .tracked(.wide)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                        .padding(.bottom, 14)

                        // ── Title ──
                        Text("Offer Letter")
                            .font(AppFont.serif(28))
                            .foregroundColor(.primaryText)
                            .padding(.bottom, 8)

                        Text("We'll pull your income and start date to model your repayment capacity.")
                            .font(AppFont.body)
                            .foregroundColor(.secondaryText)
                            .lineSpacing(3)
                            .padding(.bottom, 24)

                        // ── Upload Card ──
                        Button(action: { showFilePicker = true }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.primaryTint)
                                        .frame(width: 56, height: 56)

                                    if isExtracting {
                                        ProgressView()
                                            .scaleEffect(0.9)
                                            .tint(.primary)
                                    } else {
                                        Text(hasUploaded ? "✓" : "💼")
                                            .font(.system(size: hasUploaded ? 22 : 26))
                                    }
                                }

                                Text(hasUploaded ? "Re-upload Offer Letter" : "Upload Offer Letter")
                                    .font(AppFont.bodySemibold)
                                    .foregroundColor(.primaryText)

                                Text("PDF or image of your offer letter")
                                    .font(AppFont.caption)
                                    .foregroundColor(.secondaryText)

                                HStack(spacing: 6) {
                                    ForEach(["PDF", "JPG"], id: \.self) { label in
                                        Text(label)
                                            .font(AppFont.tag)
                                            .foregroundColor(.secondaryText)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.subtleBg)
                                            )
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        hasUploaded ? Color.primary.opacity(0.4) : Color.divider,
                                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 20)

                        // ── Divider ──
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(Color.divider)
                            Text("or enter manually")
                                .font(AppFont.caption)
                                .foregroundColor(.secondaryText)
                                .fixedSize()
                            Rectangle().frame(height: 1).foregroundColor(Color.divider)
                        }
                        .padding(.bottom, 20)

                        // ── Editable Fields ──
                        OfferField(label: "ANNUAL SALARY",   value: $offerData.annualSalary,   placeholder: "e.g. $78,000")
                        OfferField(label: "LOCATION",        value: $offerData.location,        placeholder: "e.g. New York, NY")
                        OfferField(label: "EMPLOYMENT TYPE", value: $offerData.employmentType,  placeholder: "e.g. Full-Time / W-2")

                        if !offerData.jobTitle.isEmpty {
                            OfferField(label: "JOB TITLE", value: $offerData.jobTitle, placeholder: "e.g. Software Engineer")
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }

                // ── CTA ──
                Button(action: { onContinue(offerData.toJobOfferIn()) }) {
                    Text("Save & Continue")
                        .font(AppFont.ctaButton)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            offerData.annualSalary.isEmpty ? Color.subtleBg : Color.primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(offerData.annualSalary.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .padding(.top, 12)
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .jpeg, .png],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                handleFile(url: url)
            }
        }
        .alert("Could Not Extract", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func handleFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        isExtracting = true
        OfferLetterExtractor.extract(from: url) { result in
            url.stopAccessingSecurityScopedResource()
            DispatchQueue.main.async {
                isExtracting = false
                switch result {
                case .success(let data):
                    if !data.annualSalary.isEmpty   { offerData.annualSalary   = data.annualSalary }
                    if !data.startDate.isEmpty      { offerData.startDate      = data.startDate }
                    if !data.employmentType.isEmpty { offerData.employmentType = data.employmentType }
                    if !data.location.isEmpty       { offerData.location       = data.location }
                    if !data.jobTitle.isEmpty       { offerData.jobTitle       = data.jobTitle }
                    hasUploaded = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Offer Field Component

struct OfferField: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(AppFont.sectionLabel)
                .foregroundColor(.secondaryText)
                .tracked(.wide)

            HStack {
                TextField(placeholder, text: $value)
                    .font(AppFont.bodySemibold)
                    .foregroundColor(.primaryText)
                    .focused($focused)

                if !focused {
                    Button("Edit") { focused = true }
                        .font(AppFont.smallButton)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    focused ? Color.primary.opacity(0.5) : Color.cardBorder,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: focused)
        .padding(.bottom, 10)
    }
}

#Preview {
    OfferLetterView()
}
