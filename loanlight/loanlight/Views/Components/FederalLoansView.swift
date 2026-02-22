import SwiftUI
internal import UniformTypeIdentifiers

struct FederalLoansView: View {
    var currentStep: Int = 1
    var totalSteps: Int = 6
    var onComplete: ([LoanEntity]) -> Void = { _ in }

    @StateObject private var viewModel = FederalLoansViewModel()
    @State private var showFilePicker = false
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        stepPill
                            .padding(.bottom, 14)

                        Text("Federal Loans")
                            .font(AppFont.serif(28))
                            .foregroundColor(.ink)
                            .padding(.bottom, 8)

                        Text("Upload your FAFSA / StudentAid.gov PDF\nto auto-import your loan details.")
                            .font(AppFont.body)
                            .foregroundColor(.mist)
                            .lineSpacing(3)
                            .padding(.bottom, 28)

                        // Confirmed loans
                        if !viewModel.confirmedLoans.isEmpty {
                            confirmedLoansSection
                                .padding(.bottom, 20)
                        }

                        uploadCard
                            .padding(.bottom, 12)

                        importDirectlyCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }

                bottomButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                    .padding(.top, 12)
            }

            if viewModel.isLoading { loadingOverlay }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.extractFromURL(url)
            }
        }
        .sheet(isPresented: $viewModel.showConfirmation) {
            if let loan = viewModel.extractedLoan {
                LoanConfirmationSheet(loan: loan, onConfirm: {
                    viewModel.confirmExtractedLoan()
                })
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Submit federal loans to backend (replace_all_federal_loans)

    private func submitFederalLoans() {
        let loans = viewModel.confirmedLoans
        guard !loans.isEmpty else { return }
        viewModel.errorMessage = nil
        isSubmitting = true
        Task {
            defer { Task { @MainActor in isSubmitting = false } }
            let payload = FederalLoanBulkIn(loans: loans.map { $0.toFederalLoanIn() })
            do {
                _ = try await APIClient.post(path: "/federal-loans/bulk", body: payload) as FederalLoanBulkOut
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Could not save federal loans. Please try again."
                }
                return
            }
            await MainActor.run {
                onComplete(viewModel.confirmedLoans)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .frame(height: 3)
                    .foregroundColor(step <= currentStep ? .sage : .border)
            }
        }
    }

    // MARK: - Step Pill

    private var stepPill: some View {
        HStack(spacing: 6) {
            Circle()
                .frame(width: 6, height: 6)
                .foregroundColor(.sage)
            Text("STEP \(currentStep) OF \(totalSteps)")
                .font(AppFont.microBold)
                .foregroundColor(.sage)
                .kerning(0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().stroke(Color.sage.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Confirmed Loans

    private var confirmedLoansSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADDED LOANS")
                .font(AppFont.sectionLabel)
                .tracking(1.2)
                .foregroundColor(.mist)

            ForEach(viewModel.confirmedLoans) { loan in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                        .font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loan.loanType.isEmpty ? "Federal Loan" : loan.loanType)
                            .font(AppFont.bodySemibold)
                            .foregroundColor(.ink)
                        Text([loan.totalBalance, loan.interestRate]
                            .filter { !$0.isEmpty }
                            .joined(separator: " · "))
                            .font(AppFont.caption)
                            .foregroundColor(.mist)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
            }
        }
    }

    // MARK: - Upload Card

    private var uploadCard: some View {
        Button(action: { showFilePicker = true }) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.sagetint)
                        .frame(width: 52, height: 52)
                    Image(systemName: "doc.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.sage.opacity(0.7))
                }
                Text("Upload FAFSA PDF")
                    .font(AppFont.bodySemibold)
                    .foregroundColor(.ink)
                Text("From StudentAid.gov or your servicer")
                    .font(AppFont.caption)
                    .foregroundColor(.mist)
                    .multilineTextAlignment(.center)
                Text("PDF")
                    .font(AppFont.microBold)
                    .foregroundColor(.mist)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.surface)
                    .cornerRadius(6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.border, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Import Directly Card

    private var importDirectlyCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("OR IMPORT DIRECTLY")
                    .font(AppFont.microBold)
                    .foregroundColor(.mist)
                    .kerning(0.5)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.border).padding(.leading, 16)

            HStack(spacing: 10) {
                Text("🔗").font(.system(size: 16))
                Text("Connect StudentAid.gov")
                    .font(AppFont.bodyMedium)
                    .foregroundColor(.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.mist)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.border, lineWidth: 1))
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 10) {
            Button(action: { showFilePicker = true }) {
                Text("Upload PDF")
                    .font(AppFont.ctaButton)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.sage)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button(action: {}) {
                Text("Enter Manually")
                    .font(AppFont.ctaButton)
                    .foregroundColor(.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.border, lineWidth: 1.5)
                    )
            }

            if !viewModel.confirmedLoans.isEmpty {
                Button(action: { submitFederalLoans() }) {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.ink)
                        } else {
                            Text("Continue")
                                .font(AppFont.ctaButton)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundColor(.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isSubmitting)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.confirmedLoans.count)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.4).tint(.white)
                Text("Extracting loan data…")
                    .font(AppFont.captionBold)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.ink.opacity(0.9))
            )
        }
    }
}

// MARK: - Preview
#Preview {
    FederalLoansView(currentStep: 1, totalSteps: 6)
}
