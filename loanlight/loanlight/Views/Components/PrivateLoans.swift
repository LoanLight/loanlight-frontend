//
//  Federal.swift
//  loanlight
//
//  Created by Sruthy Mammen on 2/21/26.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct PrivateLoanFile: Identifiable {
    let id = UUID()
    var fileName: String
    var extractedData: ExtractedLoanData?
    var isExtracting: Bool = false
    var failed: Bool = false

    /// Converts extracted data to the backend request model
    func toPrivateLoanIn() -> PrivateLoanIn? {
        guard let data = extractedData else { return nil }
        let balance = Decimal(string: data.totalBalance
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")) ?? 0
        let rate = Decimal(string: data.interestRate
            .replacingOccurrences(of: "%", with: "")) ?? 0
        let payment = Decimal(string: data.monthlyPayment
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")) ?? 0
        return PrivateLoanIn(
            lenderName: data.servicer.isEmpty ? fileName : data.servicer,
            currentBalance: balance,
            interestRate: rate,
            minMonthlyPayment: payment
        )
    }
}

struct PrivateLoansView: View {

    var currentStep: Int = 2
    var totalSteps: Int = 6
    /// Returns validated PrivateLoanIn array to the parent
    var onContinue: ([PrivateLoanIn]) -> Void = { _ in }

    @State private var uploadedFiles: [PrivateLoanFile] = []
    @State private var showFilePicker = false
    @State private var selectedFile: PrivateLoanFile? = nil

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
                        Text("Private Loans")
                            .font(AppFont.serif(28))
                            .foregroundColor(.primaryText)
                            .padding(.bottom, 8)

                        Text("Upload statements from Sallie Mae, Discover, or any private lender.")
                            .font(AppFont.body)
                            .foregroundColor(.secondaryText)
                            .lineSpacing(3)
                            .padding(.bottom, 24)

                        // ── Uploaded Files ──
                        ForEach($uploadedFiles) { $file in
                            UploadedFileRow(
                                file: $file,
                                onTap: { selectedFile = file },
                                onDelete: { removeFile(file) }
                            )
                            .padding(.bottom, 10)
                        }

                        // ── Add File Card ──
                        Button(action: { showFilePicker = true }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.primaryTint)
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "plus")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(.primary)
                                }

                                Text(uploadedFiles.isEmpty ? "Upload Private Loan Statement" : "Add Another Lender")
                                    .font(AppFont.bodySemibold)
                                    .foregroundColor(.primaryText)

                                Text("PDF, photo, or doc — we'll extract it")
                                    .font(AppFont.caption)
                                    .foregroundColor(.secondaryText)

                                HStack(spacing: 6) {
                                    ForEach(["PDF", "JPG", "PNG"], id: \.self) { label in
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
                                        Color.divider,
                                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }

                // ── Bottom Buttons ──
                VStack(spacing: 10) {
                    Button(action: {
                        let loans = uploadedFiles.compactMap { $0.toPrivateLoanIn() }
                        onContinue(loans)
                    }) {
                        Text("Confirm & Continue")
                            .font(AppFont.ctaButton)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(uploadedFiles.isEmpty ? Color.subtleBg : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(uploadedFiles.isEmpty)

                    Button(action: { onContinue([]) }) {
                        Text("No private loans — Skip")
                            .font(AppFont.body)
                            .foregroundColor(.secondaryText)
                    }
                }
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
                handleFileSelected(url: url)
            }
        }
        .sheet(item: $selectedFile) { file in
            if let data = file.extractedData {
                PrivateLoanConfirmationView(
                    fileName: file.fileName,
                    extractedData: data
                ) { confirmed in
                    updateExtractedData(for: file.id, with: confirmed)
                    selectedFile = nil
                }
            }
        }
    }

    private func handleFileSelected(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        var newFile = PrivateLoanFile(fileName: url.lastPathComponent)
        newFile.isExtracting = true
        uploadedFiles.append(newFile)
        let fileId = newFile.id

        LoanPDFExtractor.extract(from: url) { result in
            url.stopAccessingSecurityScopedResource()
            DispatchQueue.main.async {
                guard let index = uploadedFiles.firstIndex(where: { $0.id == fileId }) else { return }
                switch result {
                case .success(let data):
                    uploadedFiles[index].extractedData = data
                    uploadedFiles[index].isExtracting = false
                    selectedFile = uploadedFiles[index]
                case .failure:
                    uploadedFiles[index].isExtracting = false
                    uploadedFiles[index].failed = true
                }
            }
        }
    }

    private func removeFile(_ file: PrivateLoanFile) {
        uploadedFiles.removeAll { $0.id == file.id }
    }

    private func updateExtractedData(for id: UUID, with data: ExtractedLoanData) {
        if let index = uploadedFiles.firstIndex(where: { $0.id == id }) {
            uploadedFiles[index].extractedData = data
        }
    }
}

// MARK: - Uploaded File Row

struct UploadedFileRow: View {
    @Binding var file: PrivateLoanFile
    var onTap: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.system(size: 20))
                .foregroundColor(.secondaryText)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(AppFont.captionMedium)
                    .foregroundColor(.primaryText)
                    .lineLimit(1)

                if let data = file.extractedData, !data.totalBalance.isEmpty {
                    Text("\(data.totalBalance) · \(data.interestRate)")
                        .font(AppFont.caption)
                        .foregroundColor(.secondaryText)
                }
            }

            Spacer()

            if file.isExtracting {
                ProgressView().scaleEffect(0.8)
            } else if file.failed {
                Text("Failed")
                    .font(AppFont.captionBold)
                    .foregroundColor(.danger)
            } else {
                Text("✓ Extracted")
                    .font(AppFont.captionBold)
                    .foregroundColor(.primary)
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(.systemGray4))
                    .font(.system(size: 18))
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .onTapGesture { onTap() }
    }
}

// MARK: - Private Loan Confirmation Sheet

struct PrivateLoanConfirmationView: View {
    let fileName: String
    @State var extractedData: ExtractedLoanData
    var onSave: (ExtractedLoanData) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
    NavigationView {
            ZStack {
    Color.screenBg.ignoresSafeArea()
    ScrollView {
                    VStack(alignment: .leading, spacing: 10) {

                        HStack(spacing: 6) {
                            Image(systemName: "doc.fill")
                                .font(AppFont.micro)
                            Text(fileName)
                                .font(AppFont.captionBold)
                                .lineLimit(1)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.primaryTint)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 4)

                        EditableField(label: "SERVICER",        value: $extractedData.servicer)
                        EditableField(label: "TOTAL BALANCE",   value: $extractedData.totalBalance)
                        EditableField(label: "LOAN TYPE",       value: $extractedData.loanType)
                        EditableField(label: "INTEREST RATE",   value: $extractedData.interestRate)
                        EditableField(label: "REPAYMENT PLAN",  value: $extractedData.repaymentPlan)
                        EditableField(label: "MONTHLY PAYMENT", value: $extractedData.monthlyPayment)
                        EditableField(label: "LOAN STATUS",     value: $extractedData.loanStatus)

                        Button(action: { onSave(extractedData); dismiss() }) {
                            Text("Save Loan")
                                .font(AppFont.ctaButton)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 17)
                                .background(Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Confirm Loan Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }.foregroundColor(.primary)
                }
            }
        }
}
}

#Preview {
    PrivateLoansView()
}
