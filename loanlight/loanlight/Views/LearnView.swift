import SwiftUI
import AVFoundation
import Combine

// MARK: - Data Models

struct Lesson: Identifiable, Hashable {
    let id: String
    let title: String
    let promise: String
    let readMinutes: Int
    let topic: LessonTopic
    let keyTakeaways: [String]
    let bodyText: String
    let actionLabel: String?
    let isStartHere: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Lesson, rhs: Lesson) -> Bool { lhs.id == rhs.id }
}

enum LessonTopic: String, CaseIterable {
    case debt      = "Paying Off Debt"
    case investing = "Investing Basics"
    case budgeting = "Budgeting"
    case credit    = "Credit"
    case lifeAfter = "Life After Grad"

    var icon: String {
        switch self {
        case .debt:      return "arrow.down.circle"
        case .investing: return "chart.line.uptrend.xyaxis"
        case .budgeting: return "list.bullet.rectangle"
        case .credit:    return "creditcard"
        case .lifeAfter: return "graduationcap"
        }
    }

    var color: Color {
        switch self {
        case .debt:      return .sage
        case .investing: return .gold
        case .budgeting: return Color(hex: "#6B7280")
        case .credit:    return Color(hex: "#9B6B9B")
        case .lifeAfter: return Color(hex: "#C47C5A")
        }
    }
}

// MARK: - Content Library

struct LessonLibrary {
    static let all: [Lesson] = [
        Lesson(id: "student-loans-101", title: "Student Loans 101",
               promise: "Understand what you owe and why it matters in 5 minutes.",
               readMinutes: 4, topic: .debt,
               keyTakeaways: [
                "Federal loans are subsidized (gov pays interest while in school) or unsubsidized (interest accrues immediately).",
                "Your loan servicer is the company you pay — not the government. They can change.",
                "Interest accrues daily. A $30,000 loan at 5.5% accrues ~$4.52 per day.",
                "Repayment plans (SAVE, IBR, Standard) dramatically change what you pay monthly and over your lifetime.",
                "LoanLight uses your real balance and rate to model all of this for you."
               ],
               bodyText: "Most people leave school with loans but no real map. You know the number — but not why it moves, how the interest stacks, or what your repayment options mean for your life. This lesson gives you that map in plain English.",
               actionLabel: "See your loan details", isStartHere: true),

        Lesson(id: "avalanche-snowball-hybrid", title: "Avalanche vs Snowball vs Hybrid",
               promise: "Know which payoff strategy fits you in 5 minutes.",
               readMinutes: 5, topic: .debt,
               keyTakeaways: [
                "Avalanche: extra money goes to the highest-rate loan first. Mathematically optimal — saves the most interest.",
                "Snowball: pay off the smallest balance first. Builds psychological momentum.",
                "Hybrid: target the loan with the best combo of high rate + small balance. LoanLight's default.",
                "The best strategy is the one you'll actually stick with.",
                "The difference in total interest between Avalanche and Snowball is often less than $1,000 over a decade."
               ],
               bodyText: "The internet makes this sound like a math test. It's not. It's a personality test. Here's what actually separates the three strategies — and how to pick yours.",
               actionLabel: "Try each strategy on your loans", isStartHere: true),

        Lesson(id: "what-is-risk-level", title: "What Does 'Risk Level' Mean?",
               promise: "Decode low / moderate / high risk in plain English.",
               readMinutes: 3, topic: .investing,
               keyTakeaways: [
                "Risk level asks: how much temporary loss can you handle without panic-selling?",
                "Low risk (~4–5% return): more bonds, less stocks. Smoother ride, lower ceiling.",
                "Moderate risk (~6–7% return): balanced blend. Standard for most people.",
                "High risk (~8–9% return): heavy stocks. Great long-term but drops hard in recessions.",
                "LoanLight uses these return assumptions to project your investment growth."
               ],
               bodyText: "Risk in investing isn't about being reckless. It's about the tradeoff between short-term volatility and long-term return. A higher risk tolerance means you can let the number drop for a year without selling — and that patience gets rewarded.",
               actionLabel: "Adjust risk level in your plan", isStartHere: true),

        Lesson(id: "investing-grows-over-time", title: "How Investing Grows Over Time",
               promise: "See why starting early matters more than investing a lot.",
               readMinutes: 4, topic: .investing,
               keyTakeaways: [
                "Compounding means you earn returns on your returns, not just your contributions.",
                "$200/month at 7% for 10 years = ~$34,700. You put in $24,000, earned $10,700 extra.",
                "$200/month at 7% for 30 years = ~$243,000. You put in $72,000, earned $171,000 extra.",
                "Starting 5 years earlier is worth more than doubling your monthly contribution.",
                "Even $50/month invested while paying off debt may beat waiting until loans are gone."
               ],
               bodyText: "Everyone says 'start early.' Almost no one explains why with numbers. Here's the honest math behind the most repeated advice in personal finance.",
               actionLabel: "Toggle investing in your plan", isStartHere: true),

        Lesson(id: "pay-extra", title: "What Happens When You Pay Extra?",
               promise: "See how $100/month extra changes your payoff date and total cost.",
               readMinutes: 4, topic: .debt,
               keyTakeaways: [
                "Extra payments go directly to principal — reducing the balance that interest is calculated on.",
                "On a $30,000 loan at 5.5%, paying $100/month extra saves ~$1,800 and cuts 14 months off.",
                "The earlier you overpay, the bigger the impact.",
                "Even one extra payment per year meaningfully shortens most 10-year loans.",
                "LoanLight's slider shows this in real-time as you move your monthly commitment up."
               ],
               bodyText: "You don't need a windfall to get ahead on your loans. Small extra payments compound into significant savings when applied early.",
               actionLabel: "Move the payment slider", isStartHere: false),

        Lesson(id: "interest-explained", title: "Interest Explained With One Example",
               promise: "Understand exactly how your daily interest is calculated.",
               readMinutes: 3, topic: .debt,
               keyTakeaways: [
                "Federal loan interest formula: (Balance × Annual Rate) ÷ 365.",
                "Example: $27,000 at 4.99% = $3.69/day in interest.",
                "Each payment first pays off accrued interest, then reduces principal.",
                "If your payment is less than that month's interest, your balance can grow (negative amortization).",
                "SAVE plan protects against this — the government covers unpaid interest."
               ],
               bodyText: "Interest feels abstract until you see it as a daily number. Once you do, the urgency of extra payments and the value of income-driven protections becomes obvious.",
               actionLabel: nil, isStartHere: false),

        Lesson(id: "invest-while-paying-minimums", title: "Invest While Paying Minimums: When It Helps",
               promise: "The math behind paying debt AND investing at the same time.",
               readMinutes: 5, topic: .investing,
               keyTakeaways: [
                "If your loan rate is lower than your expected investment return, investing wins mathematically.",
                "Example: 4.5% loan vs 7% expected return — investing the extra $200 beats paying the loan faster.",
                "But: investments are uncertain. Your 7% isn't guaranteed. Your 4.5% debt savings are.",
                "Psychological peace of mind has value. Debt-free is worth something beyond math.",
                "LoanLight models both so you see the actual difference in your numbers."
               ],
               bodyText: "This is the most argued topic in personal finance forums. The honest answer: it depends on your rate, return assumption, and your relationship with uncertainty.",
               actionLabel: "Compare strategies in your plan", isStartHere: false),

        Lesson(id: "risk-volatility", title: "Risk & Volatility Explained",
               promise: "Why your balance goes down sometimes — and why that's fine.",
               readMinutes: 4, topic: .investing,
               keyTakeaways: [
                "Volatility is normal. A 60/40 portfolio might drop 15% in a bad year and recover in 2.",
                "The S&P 500 has been positive in 73% of calendar years since 1928.",
                "Selling during a crash locks in your losses. Not selling is the hardest skill.",
                "Time horizon is everything. If you won't need it for 10+ years, short-term drops don't matter.",
                "LoanLight's high risk setting assumes ~8% returns — historically achievable, not guaranteed."
               ],
               bodyText: "Watching your portfolio drop is uncomfortable. Here's why that discomfort is the price of higher long-term returns.",
               actionLabel: "Change your risk level", isStartHere: false),

        Lesson(id: "essentials-vs-discretionary", title: "Essentials vs. Discretionary: No Shame",
               promise: "Estimate your monthly expenses without a spreadsheet.",
               readMinutes: 3, topic: .budgeting,
               keyTakeaways: [
                "Essentials: rent, utilities, groceries, transportation, insurance, loan minimums.",
                "Discretionary: dining, subscriptions, clothing, entertainment, travel.",
                "The 50/30/20 rule: 50% needs, 30% wants, 20% savings/debt.",
                "Most people underestimate discretionary by 30–40%. Subscriptions alone average $219/month.",
                "A rough budget is infinitely better than no budget."
               ],
               bodyText: "Budgeting gets moralized in personal finance. This isn't that. This is just: what comes in, what goes out, what's left.",
               actionLabel: nil, isStartHere: false),

        Lesson(id: "rent-changes", title: "What If Rent Changes?",
               promise: "How a rent increase or move affects your whole financial plan.",
               readMinutes: 3, topic: .budgeting,
               keyTakeaways: [
                "Rent is typically your largest expense. A $300/month increase = $3,600/year less for loans or investing.",
                "Moving to a cheaper city can accelerate your freedom date by years.",
                "Classic rule: rent ≤ 30% of gross income. In high-cost cities, aim for ≤ 35%.",
                "Every dollar freed in housing can be redirected to your plan.",
                "LoanLight's monthly commitment slider is exactly how you'd model a rent change."
               ],
               bodyText: "Where you live is the single biggest financial lever most people have. Here's how to think about that decision in the context of your debt and investment goals.",
               actionLabel: "Adjust your monthly commitment", isStartHere: false),

        Lesson(id: "first-salary", title: "Your First Salary: What to Do First",
               promise: "A clear order of operations for your first real paycheck.",
               readMinutes: 5, topic: .lifeAfter,
               keyTakeaways: [
                "Step 1: Emergency fund — 1 month of expenses in a HYSA before anything else.",
                "Step 2: Get your employer 401k match. It's an instant 50–100% return.",
                "Step 3: Pay minimums on all loans. Missing payments destroys credit.",
                "Step 4: Extra debt payments OR Roth IRA — depends on your interest rates.",
                "Step 5: Build emergency fund to 3–6 months while doing step 4."
               ],
               bodyText: "First salary is exciting and overwhelming. Here's a simple priority order that applies to most new grads — with the logic behind each step.",
               actionLabel: nil, isStartHere: false),

        Lesson(id: "taxes-after-grad", title: "Taxes After Graduation: The Basics",
               promise: "Three things every new grad needs to know about taxes.",
               readMinutes: 4, topic: .lifeAfter,
               keyTakeaways: [
                "Your marginal rate is NOT what you pay on all income. The US uses tax brackets.",
                "Student loan interest up to $2,500/year is tax deductible under ~$85k income.",
                "A Roth IRA uses after-tax dollars but grows tax-free — ideal early in your career.",
                "W-4 withholding: set it correctly or you'll owe a lump sum in April.",
                "Contributing to a 401k reduces taxable income. $5,000 in the 22% bracket saves $1,100."
               ],
               bodyText: "Nobody teaches you taxes in school. Here's the minimum you need to know to not get surprised — and to make smarter decisions about where to put your money.",
               actionLabel: nil, isStartHere: false),

        Lesson(id: "credit-score", title: "Credit Score: What Actually Moves It",
               promise: "The 5 factors — ranked by how much they actually matter.",
               readMinutes: 4, topic: .credit,
               keyTakeaways: [
                "Payment history (35%): one missed payment can drop your score 60–110 points.",
                "Credit utilization (30%): keep balances below 30% of your limit. Below 10% is ideal.",
                "Length of history (15%): your oldest account matters. Don't close old cards.",
                "Credit mix (10%): having both cards and loans helps slightly.",
                "New inquiries (10%): applying for multiple cards quickly hurts temporarily."
               ],
               bodyText: "Credit scores feel mysterious because no one explains the math. Here are the actual factors — with weights — so you can prioritize what moves the needle.",
               actionLabel: nil, isStartHere: false),
    ]

    static var startHere: [Lesson] { all.filter { $0.isStartHere } }
    static func lessons(for topic: LessonTopic) -> [Lesson] { all.filter { $0.topic == topic } }
    static func recommended(investingEnabled: Bool) -> [Lesson] {
        let topic: LessonTopic = investingEnabled ? .investing : .debt
        let nonStartHere = all.filter { $0.topic == topic && !$0.isStartHere }
        return nonStartHere.count >= 2 ? nonStartHere : all.filter { $0.topic == topic }
    }
}

// MARK: - LearnView

struct LearnView: View {
    var investingEnabled: Bool = true
    @Binding var selectedTab: Int

    @State private var searchText    = ""
    @State private var selectedTopic: LessonTopic? = nil
    @State private var selectedLesson: Lesson?     = nil

    var filteredLessons: [Lesson] {
        let base = selectedTopic.map { LessonLibrary.lessons(for: $0) } ?? LessonLibrary.all
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.promise.localizedCaseInsensitiveContains(searchText) ||
            $0.topic.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var isFiltering: Bool { !searchText.isEmpty || selectedTopic != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    searchSection
                    if isFiltering {
                        filteredSection
                    } else {
                        homeSection
                    }
                }
            }
            .background(Color.paper)
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson, selectedTab: $selectedTab)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Learn")
                .font(AppFont.serif(28))
                .foregroundColor(.ink)
            Text("Short lessons. Real decisions.")
                .font(AppFont.body)
                .foregroundColor(.mist)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 24)
    }

    private var searchSection: some View {
        LearnSearchBar(text: $searchText)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
    }

    private var homeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            LearnSectionHeader(title: "Start Here", subtitle: "New? Begin with these four.")
            startHereRow.padding(.bottom, 32)
            LearnSectionHeader(title: "Browse by Topic", subtitle: nil)
            topicChipRow.padding(.bottom, 32)
            LearnSectionHeader(
                title: "Recommended for You",
                subtitle: investingEnabled ? "Based on your investing plan" : "Based on your payoff plan"
            )
            recommendedList.padding(.bottom, 40)
        }
    }

    private var filteredSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                if let topic = selectedTopic {
                    HStack(spacing: 6) {
                        Image(systemName: topic.icon).font(.system(size: 11, weight: .semibold))
                        Text(topic.rawValue).font(AppFont.microBold)
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedTopic = nil }
                        } label: {
                            Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                        }
                    }
                    .foregroundColor(topic.color)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(topic.color.opacity(0.12))
                    .clipShape(Capsule())
                }
                Text("\(filteredLessons.count) result\(filteredLessons.count == 1 ? "" : "s")")
                    .font(AppFont.caption).foregroundColor(.mist)
                Spacer()
                Button {
                    withAnimation { searchText = ""; selectedTopic = nil }
                } label: {
                    Text("Clear all").font(AppFont.caption).foregroundColor(.mist).underline()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            LessonListSection(lessons: filteredLessons, onTap: { selectedLesson = $0 })
                .padding(.bottom, 40)
        }
    }

    private var startHereRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(LessonLibrary.startHere) { lesson in
                    StartHereCard(lesson: lesson).onTapGesture { selectedLesson = lesson }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var topicChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LessonTopic.allCases, id: \.self) { topic in
                    TopicChip(topic: topic, isSelected: selectedTopic == topic)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTopic = selectedTopic == topic ? nil : topic
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var recommendedList: some View {
        LessonListSection(
            lessons: LessonLibrary.recommended(investingEnabled: investingEnabled),
            onTap: { selectedLesson = $0 }
        )
    }
}

// MARK: - Reusable Sub-Views

struct LearnSectionHeader: View {
    let title: String
    let subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppFont.serifBold(17)).foregroundColor(.ink)
            if let sub = subtitle {
                Text(sub).font(AppFont.caption).foregroundColor(.mist)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }
}

struct LearnSearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundColor(.mist)
            TextField("Search lessons…", text: $text).font(AppFont.body).foregroundColor(.ink)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.mist).font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
    }
}

struct LessonListSection: View {
    let lessons: [Lesson]
    let onTap: (Lesson) -> Void
    var body: some View {
        VStack(spacing: 12) {
            if lessons.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 32)).foregroundColor(.border)
                    Text("No lessons found").font(AppFont.body).foregroundColor(.mist)
                }
                .frame(maxWidth: .infinity).padding(.top, 60)
            } else {
                ForEach(lessons) { lesson in
                    LessonRow(lesson: lesson).onTapGesture { onTap(lesson) }.padding(.horizontal, 20)
                }
            }
        }
    }
}

struct StartHereCard: View {
    let lesson: Lesson
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            topicBadge
            Text(lesson.title).font(AppFont.serifBold(16)).foregroundColor(.ink).lineLimit(2)
            Text(lesson.promise).font(AppFont.caption).foregroundColor(.mist).lineLimit(2)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "clock").font(.system(size: 11))
                Text("\(lesson.readMinutes) min read").font(AppFont.microBold)
            }
            .foregroundColor(.mist)
        }
        .padding(18)
        .frame(width: 220, height: 190)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.border, lineWidth: 1))
        .shadow(color: Color.ink.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var topicBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: lesson.topic.icon).font(.system(size: 11, weight: .semibold))
            Text(lesson.topic.rawValue).font(AppFont.microBold)
        }
        .foregroundColor(lesson.topic.color)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(lesson.topic.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct TopicChip: View {
    let topic: LessonTopic
    let isSelected: Bool
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: topic.icon).font(.system(size: 12, weight: .medium))
            Text(topic.rawValue).font(AppFont.microBold)
        }
        .foregroundColor(isSelected ? .paper : topic.color)
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(isSelected ? topic.color : topic.color.opacity(0.1))
        .clipShape(Capsule())
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

struct LessonRow: View {
    let lesson: Lesson
    var body: some View {
        HStack(spacing: 14) {
            Circle().fill(lesson.topic.color).frame(width: 10, height: 10).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title).font(AppFont.bodyBold).foregroundColor(.ink).lineLimit(2)
                Text(lesson.promise).font(AppFont.caption).foregroundColor(.mist).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium)).foregroundColor(.border)
                Text("\(lesson.readMinutes)m").font(AppFont.microBold).foregroundColor(.mist)
            }
        }
        .padding(16)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.border, lineWidth: 1))
    }
}

// MARK: - Lesson Detail View

struct LessonDetailView: View {
    let lesson: Lesson
    @Binding var selectedTab: Int
    @Environment(\.dismiss) var dismiss
    @StateObject private var tts = ElevenLabsService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                detailHeader
                detailBody
                takeawaysCard
                actionButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .background(Color.paper)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                        Text("Learn").font(AppFont.body)
                    }
                    .foregroundColor(.sage)
                }
            }
        }
        .onDisappear { tts.stop() }
        .alert("Audio Error", isPresented: Binding(
            get: { if case .error = tts.playbackState { return true }; return false },
            set: { if !$0 { tts.stop() } }
        )) {
            Button("OK") { tts.stop() }
        } message: {
            if case .error(let msg) = tts.playbackState { Text(msg) }
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: lesson.topic.icon).font(.system(size: 12, weight: .semibold))
                Text(lesson.topic.rawValue).font(AppFont.microBold)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 11))
                    Text("\(lesson.readMinutes) min read").font(AppFont.microBold)
                }
                .foregroundColor(.mist)
            }
            .foregroundColor(lesson.topic.color)
            .padding(.bottom, 16)

            Text(lesson.title).font(AppFont.serif(26)).foregroundColor(.ink).padding(.bottom, 10)
            Text(lesson.promise).font(AppFont.body).foregroundColor(.mist).padding(.bottom, 28)
            Rectangle().fill(Color.border).frame(height: 1).padding(.bottom, 20)

            InlineTTSRow(state: tts.playbackState) { tts.toggle(lesson: lesson) }
                .padding(.bottom, 28)
        }
    }

    private var detailBody: some View {
        Text(lesson.bodyText)
            .font(AppFont.body).foregroundColor(.ink).lineSpacing(6).padding(.bottom, 32)
    }

    private var takeawaysCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Key Takeaways").font(AppFont.serifBold(17)).foregroundColor(.ink).padding(.bottom, 16)
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(lesson.keyTakeaways.enumerated()), id: \.offset) { i, takeaway in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)")
                            .font(AppFont.microBold)
                            .foregroundColor(lesson.topic.color)
                            .frame(width: 22, height: 22)
                            .background(lesson.topic.color.opacity(0.1))
                            .clipShape(Circle())
                            .padding(.top, 1)
                        Text(takeaway)
                            .font(AppFont.body).foregroundColor(.ink).lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private var actionButton: some View {
        if let label = lesson.actionLabel {
            Button(action: {
                dismiss()
                // Small delay so the nav pop animation completes before switching tabs
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    selectedTab = 0
                }
            }) {
                HStack(spacing: 8) {
                    Text(label).font(AppFont.ctaButton)
                    Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.paper)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient(colors: [.sage, .sage.opacity(0.85)], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - TTS Components

struct InlineTTSRow: View {
    let state: TTSPlaybackState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(iconBackground).frame(width: 36, height: 36)
                    if case .loading = state {
                        ProgressView().scaleEffect(0.65).tint(.white)
                    } else {
                        Image(systemName: iconName).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(labelText).font(AppFont.bodyBold).foregroundColor(.ink)
                    Text(sublabelText).font(AppFont.caption).foregroundColor(.mist)
                }
                Spacer()
                if case .playing = state { SoundWaveView() }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(iconBackground.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(iconBackground.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch state {
        case .idle: return "headphones"
        case .loading: return "headphones"
        case .playing: return "pause.fill"
        case .paused: return "play.fill"
        case .error: return "exclamationmark"
        }
    }

    private var iconBackground: Color {
        switch state {
        case .playing, .loading, .paused: return .sage
        case .error: return Color(hex: "#C47C5A")
        case .idle: return Color(hex: "#6B7280")
        }
    }

    private var labelText: String {
        switch state {
        case .idle: return "Listen to this lesson"
        case .loading: return "Loading audio…"
        case .playing: return "Now playing"
        case .paused: return "Paused — tap to resume"
        case .error: return "Audio unavailable"
        }
    }

    private var sublabelText: String {
        switch state {
        case .idle: return "Powered by ElevenLabs"
        case .loading: return "Fetching voice audio"
        case .playing: return "Tap to pause"
        case .paused: return "Powered by ElevenLabs"
        case .error: return "Check your API key"
        }
    }
}

struct SoundWaveView: View {
    @State private var heights: [CGFloat] = [6, 14, 10]
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.sage)
                    .frame(width: 3, height: heights[i])
                    .animation(
                        .easeInOut(duration: 0.4 + Double(i) * 0.1)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: heights[i]
                    )
            }
        }
        .frame(width: 20, height: 20)
        .onAppear { heights = [14, 6, 12] }
    }
}

// MARK: - AppFont extension (delete if already in Theme)

extension AppFont {
    static func serifBold(_ size: CGFloat) -> Font { .custom("Georgia-Bold", size: size) }
}

// MARK: - Previews

#Preview("Learn – Home") {
    LearnView(investingEnabled: true, selectedTab: .constant(1))
}
#Preview("Learn – Investing Off") {
    LearnView(investingEnabled: false, selectedTab: .constant(1))
}
#Preview("Lesson Detail") {
    NavigationStack {
        LessonDetailView(lesson: LessonLibrary.all[0], selectedTab: .constant(1))
    }
}

