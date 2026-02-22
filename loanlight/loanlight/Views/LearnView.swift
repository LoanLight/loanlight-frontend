import SwiftUI

// MARK: - Data Models

struct Lesson: Identifiable {
    let id = UUID()
    let title: String
    let promise: String
    let readMinutes: Int
    let topic: LessonTopic
    let keyTakeaways: [String]
    let bodyText: String
    let actionLabel: String?
    let isStartHere: Bool
}

enum LessonTopic: String, CaseIterable {
    case debt       = "Paying Off Debt"
    case investing  = "Investing Basics"
    case budgeting  = "Budgeting"
    case credit     = "Credit"
    case lifeAfter  = "Life After Grad"

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

        // ── Start Here ────────────────────────────────────────────────

        Lesson(
            title: "Student Loans 101",
            promise: "Understand what you owe and why it matters in 5 minutes.",
            readMinutes: 4,
            topic: .debt,
            keyTakeaways: [
                "Federal loans come in two types: subsidized (government pays interest while in school) and unsubsidized (interest accrues immediately).",
                "Your loan servicer is the company you pay — not the government. They can change.",
                "Interest is calculated daily. A $30,000 loan at 5.5% accrues ~$4.52 per day.",
                "Repayment plans (SAVE, IBR, Standard) dramatically change what you pay monthly — and over your lifetime.",
                "LoanLight uses your real balance and rate to model all of this for you."
            ],
            bodyText: "Most people leave school with loans but no real map. You know the number — but not why it moves, how the interest stacks, or what your repayment options actually mean for your life. This lesson gives you that map in plain English.",
            actionLabel: "See your loan details",
            isStartHere: true
        ),

        Lesson(
            title: "Avalanche vs Snowball vs Hybrid",
            promise: "Know which payoff strategy fits you in 5 minutes.",
            readMinutes: 5,
            topic: .debt,
            keyTakeaways: [
                "Avalanche: pay minimums on everything, throw extra money at the highest-rate loan. Mathematically optimal — saves the most interest.",
                "Snowball: pay off the smallest balance first regardless of rate. Builds psychological momentum. Works great if motivation is the real challenge.",
                "Hybrid: target the loan with the best combo of high rate + small balance. LoanLight's default — balances math and psychology.",
                "The 'best' strategy is the one you'll actually stick with.",
                "The difference in total interest between Avalanche and Snowball is often less than $1,000 over a decade. Consistency beats perfection."
            ],
            bodyText: "The internet makes this sound like a math test. It's not. It's a personality test. Here's what actually separates the three strategies — and how to pick yours.",
            actionLabel: "Try each strategy on your loans",
            isStartHere: true
        ),

        Lesson(
            title: "What Does 'Risk Level' Mean?",
            promise: "Decode low / moderate / high risk in plain English.",
            readMinutes: 3,
            topic: .investing,
            keyTakeaways: [
                "Risk level is really a question: how much temporary loss can you stomach without panic-selling?",
                "Low risk (~4–5% return): more bonds, less stocks. Smoother ride, lower ceiling.",
                "Moderate risk (~6–7% return): balanced blend. Standard 'set it and forget it' for most people.",
                "High risk (~8–9% return): heavy stocks. Great long-term, but drops hard in recessions.",
                "LoanLight uses these return assumptions to project your investment growth."
            ],
            bodyText: "Risk in investing isn't about being reckless. It's about the tradeoff between short-term volatility and long-term return. A higher risk tolerance simply means you can let the number go down for a year without selling — and that patience gets rewarded.",
            actionLabel: "Adjust risk level in your plan",
            isStartHere: true
        ),

        Lesson(
            title: "How Investing Grows Over Time",
            promise: "See why starting early matters more than investing a lot.",
            readMinutes: 4,
            topic: .investing,
            keyTakeaways: [
                "Compounding means you earn returns on your returns. After year 1 you earn interest on $200. After year 10 you earn interest on $200 + all accumulated growth.",
                "$200/month at 7% for 10 years = ~$34,700. You put in $24,000, earned $10,700 extra.",
                "$200/month at 7% for 30 years = ~$243,000. You put in $72,000, earned $171,000 extra.",
                "Starting 5 years earlier is worth more than doubling your monthly contribution.",
                "This is why LoanLight asks: even $50/month invested while paying off debt may beat waiting until loans are gone."
            ],
            bodyText: "Everyone says 'start early.' Almost no one explains why with numbers. Here's the honest math behind the most repeated advice in personal finance.",
            actionLabel: "Toggle investing in your plan",
            isStartHere: true
        ),

        // ── Debt ──────────────────────────────────────────────────────

        Lesson(
            title: "What Happens When You Pay Extra?",
            promise: "See how $100/month extra changes your payoff date and total cost.",
            readMinutes: 4,
            topic: .debt,
            keyTakeaways: [
                "Extra payments go directly to principal — which reduces the balance that interest is calculated on.",
                "On a $30,000 loan at 5.5% on a 10-year plan, paying $100/month extra saves ~$1,800 in interest and cuts 14 months off.",
                "The earlier in the loan you overpay, the bigger the impact — because you're reducing a larger balance.",
                "Even one extra payment per year (a 13th payment) meaningfully shortens most 10-year loans.",
                "LoanLight's slider shows this in real-time as you move your monthly commitment up."
            ],
            bodyText: "You don't need a windfall to get ahead on your loans. Small extra payments compound into significant savings when applied early. Here's exactly what the math looks like.",
            actionLabel: "Move the payment slider in your plan",
            isStartHere: false
        ),

        Lesson(
            title: "Interest Explained With One Example",
            promise: "Understand exactly how your daily interest is calculated.",
            readMinutes: 3,
            topic: .debt,
            keyTakeaways: [
                "Federal loan interest accrues daily using this formula: (Balance × Annual Rate) ÷ 365.",
                "Example: $27,000 at 4.99% = ($27,000 × 0.0499) ÷ 365 = $3.69/day.",
                "Each monthly payment first pays off that accrued interest, then reduces principal.",
                "If your payment is less than that month's interest, your balance can actually grow — called negative amortization.",
                "SAVE plan protects against this: if your payment is too small, the government covers the unpaid interest."
            ],
            bodyText: "Interest feels abstract until you see it as a daily number. Once you do, the urgency of extra payments — and the value of income-driven protections — becomes obvious.",
            actionLabel: nil,
            isStartHere: false
        ),

        // ── Investing ─────────────────────────────────────────────────

        Lesson(
            title: "Invest While Paying Minimums: When It Helps",
            promise: "The math behind paying debt AND investing at the same time.",
            readMinutes: 5,
            topic: .investing,
            keyTakeaways: [
                "If your loan interest rate is lower than your expected investment return, investing wins mathematically.",
                "Example: 4.5% loan vs 7% expected return — investing the extra $200 beats paying off the loan faster.",
                "But: investments are uncertain. Your 7% isn't guaranteed. Your 4.5% debt savings are.",
                "Psychological peace of mind has value. Debt-free can be worth a few thousand dollars.",
                "LoanLight models both scenarios so you can see the actual difference in your numbers — not someone else's."
            ],
            bodyText: "This is the most argued topic in personal finance forums. The honest answer: it depends on your rate, return assumption, and your relationship with uncertainty. Here's the framework.",
            actionLabel: "Compare debt-only vs split in your plan",
            isStartHere: false
        ),

        Lesson(
            title: "Risk & Volatility Explained",
            promise: "Why your balance goes down sometimes — and why that's fine.",
            readMinutes: 4,
            topic: .investing,
            keyTakeaways: [
                "Volatility is normal fluctuation. A 60/40 portfolio might drop 15% in a bad year and recover in 2.",
                "The S&P 500 has been positive in 73% of calendar years since 1928. Long-term direction is up.",
                "Selling during a crash locks in your losses. Not selling is the hardest — and most important — skill.",
                "Time horizon is everything. If you won't need the money for 10+ years, short-term drops don't matter.",
                "LoanLight's high risk setting assumes ~8% returns — achievable historically, but not every year."
            ],
            bodyText: "Watching your portfolio drop is uncomfortable. Here's why that discomfort is the price of higher long-term returns — and how to think about it correctly.",
            actionLabel: "Change your risk level",
            isStartHere: false
        ),

        // ── Budgeting ─────────────────────────────────────────────────

        Lesson(
            title: "Essentials vs. Discretionary: No Shame",
            promise: "Estimate your monthly expenses without a spreadsheet.",
            readMinutes: 3,
            topic: .budgeting,
            keyTakeaways: [
                "Essentials: rent, utilities, groceries, transportation, insurance, minimum loan payments.",
                "Discretionary: dining out, subscriptions, clothing, entertainment, travel.",
                "The 50/30/20 rule is a starting guide: 50% needs, 30% wants, 20% savings/debt.",
                "Most people underestimate discretionary by 30–40%. Subscriptions alone average $219/month.",
                "You don't need perfect numbers — a rough budget is infinitely better than no budget."
            ],
            bodyText: "Budgeting gets moralized in personal finance. Fancy lattes blamed for poverty. That's not what this is. This is just: what comes in, what goes out, what's left. That's it.",
            actionLabel: nil,
            isStartHere: false
        ),

        Lesson(
            title: "What If Rent Changes?",
            promise: "How a rent increase or move affects your whole financial plan.",
            readMinutes: 3,
            topic: .budgeting,
            keyTakeaways: [
                "Rent is typically your largest expense. A $300/month increase = $3,600/year less for loans or investing.",
                "Moving to a cheaper city can accelerate your freedom date by years.",
                "The classic rule is rent ≤ 30% of gross income. In high-cost cities, aim for ≤ 35%.",
                "LoanLight lets you adjust monthly commitment — which is exactly how you'd model a rent change.",
                "Every dollar you free up in housing can be redirected to your plan."
            ],
            bodyText: "Where you live is the single biggest financial lever most people have. Here's how to think about that decision in the context of your debt and investment goals.",
            actionLabel: "Adjust your monthly commitment",
            isStartHere: false
        ),

        // ── Life After Grad ───────────────────────────────────────────

        Lesson(
            title: "Your First Salary: What to Do First",
            promise: "A clear order of operations for your first real paycheck.",
            readMinutes: 5,
            topic: .lifeAfter,
            keyTakeaways: [
                "Step 1: Emergency fund — 1 month of expenses in a HYSA before anything else.",
                "Step 2: Get your employer 401k match if available. It's an instant 50–100% return.",
                "Step 3: Pay minimums on all loans. Don't skip payments — it destroys credit.",
                "Step 4: Extra debt payments OR Roth IRA contributions — depends on your rates.",
                "Step 5: Build emergency fund to 3–6 months while doing step 4.",
            ],
            bodyText: "First salary is exciting and overwhelming. Everyone has advice. Here's a simple priority order that applies to most new grads — with the logic behind each step.",
            actionLabel: nil,
            isStartHere: false
        ),

        Lesson(
            title: "Taxes After Graduation: The Basics",
            promise: "The three things every new grad needs to know about taxes.",
            readMinutes: 4,
            topic: .lifeAfter,
            keyTakeaways: [
                "Your marginal rate is NOT what you pay on all income. The US uses brackets — you pay 10% on the first chunk, 12% on the next, etc.",
                "Student loan interest up to $2,500/year is tax deductible if you earn under ~$85k (single). That's real money back.",
                "A Roth IRA uses after-tax dollars now, but grows tax-free. Ideal when you're in a low bracket early in your career.",
                "W-4 withholding: set it correctly or you'll owe a lump sum in April.",
                "Contributing to a 401k reduces your taxable income — a $5,000 contribution in the 22% bracket saves $1,100 in taxes."
            ],
            bodyText: "Nobody teaches you taxes in school. Here's the minimum you need to know to not get surprised — and to make smarter decisions about where to put your money.",
            actionLabel: nil,
            isStartHere: false
        ),

        // ── Credit ────────────────────────────────────────────────────

        Lesson(
            title: "Credit Score: What Actually Moves It",
            promise: "The 5 factors — ranked by how much they actually matter.",
            readMinutes: 4,
            topic: .credit,
            keyTakeaways: [
                "Payment history (35%): pay on time, every time. One missed payment can drop your score 60–110 points.",
                "Credit utilization (30%): keep balances below 30% of your credit limit. Below 10% is ideal.",
                "Length of history (15%): your oldest account matters. Don't close old credit cards.",
                "Credit mix (10%): having both revolving (cards) and installment (loans) helps slightly.",
                "New inquiries (10%): applying for multiple cards in a short window hurts temporarily."
            ],
            bodyText: "Credit scores feel mysterious because no one explains the math. Here are the actual factors — with weights — so you can prioritize what moves the needle most.",
            actionLabel: nil,
            isStartHere: false
        ),
    ]

    static var startHere: [Lesson] { all.filter { $0.isStartHere } }

    static func lessons(for topic: LessonTopic) -> [Lesson] {
        all.filter { $0.topic == topic }
    }

    static func recommended(investingEnabled: Bool) -> [Lesson] {
        if investingEnabled {
            return all.filter { $0.topic == .investing && !$0.isStartHere }
        } else {
            return all.filter { $0.topic == .debt && !$0.isStartHere }
        }
    }
}

// MARK: - LearnView

struct LearnView: View {
    @State private var searchText = ""
    @State private var selectedTopic: LessonTopic? = nil
    @State private var selectedLesson: Lesson? = nil
    @State private var investingEnabled = true  // would come from shared state in real app

    var filteredLessons: [Lesson] {
        let base: [Lesson]
        if let topic = selectedTopic {
            base = LessonLibrary.lessons(for: topic)
        } else {
            base = LessonLibrary.all
        }
        if searchText.isEmpty { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.promise.localizedCaseInsensitiveContains(searchText) ||
            $0.topic.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ────────────────────────────────────────
                    learnHeader

                    // ── Search ────────────────────────────────────────
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    if searchText.isEmpty && selectedTopic == nil {
                        // ── Start Here ────────────────────────────────
                        sectionHeader("Start Here", subtitle: "New? Begin with these four.")
                        startHereCards
                            .padding(.bottom, 32)

                        // ── Topics ────────────────────────────────────
                        sectionHeader("Browse by Topic", subtitle: nil)
                        topicChips
                            .padding(.bottom, 32)

                        // ── Recommended ───────────────────────────────
                        sectionHeader(
                            "Recommended for You",
                            subtitle: investingEnabled ? "Based on your investing plan" : "Based on your payoff plan"
                        )
                        recommendedCards
                            .padding(.bottom, 40)

                    } else {
                        // ── Search / Topic results ────────────────────
                        if !searchText.isEmpty {
                            sectionHeader("\(filteredLessons.count) result\(filteredLessons.count == 1 ? "" : "s")", subtitle: nil)
                        }
                        lessonList(filteredLessons)
                            .padding(.bottom, 40)
                    }
                }
            }
            .background(Color.paper)
            .navigationBarHidden(true)
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
            }
        }
    }

    // MARK: - Header

    var learnHeader: some View {
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

    // MARK: - Search Bar

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.mist)
            TextField("Search lessons…", text: $searchText)
                .font(AppFont.body)
                .foregroundColor(.ink)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.mist)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.border, lineWidth: 1)
        )
    }

    // MARK: - Section Header

    func sectionHeader(_ title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppFont.serifBold(17))
                .foregroundColor(.ink)
            if let sub = subtitle {
                Text(sub)
                    .font(AppFont.caption)
                    .foregroundColor(.mist)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Start Here Cards

    var startHereCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(LessonLibrary.startHere) { lesson in
                    StartHereCard(lesson: lesson)
                        .onTapGesture { selectedLesson = lesson }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Topic Chips

    var topicChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LessonTopic.allCases, id: \.self) { topic in
                    TopicChip(
                        topic: topic,
                        isSelected: selectedTopic == topic
                    )
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

    // MARK: - Recommended Cards

    var recommendedCards: some View {
        VStack(spacing: 12) {
            ForEach(LessonLibrary.recommended(investingEnabled: investingEnabled)) { lesson in
                LessonRow(lesson: lesson)
                    .onTapGesture { selectedLesson = lesson }
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Lesson List (search / topic results)

    func lessonList(_ lessons: [Lesson]) -> some View {
        VStack(spacing: 12) {
            if lessons.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.border)
                    Text("No lessons found")
                        .font(AppFont.body)
                        .foregroundColor(.mist)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                ForEach(lessons) { lesson in
                    LessonRow(lesson: lesson)
                        .onTapGesture { selectedLesson = lesson }
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Start Here Card

struct StartHereCard: View {
    let lesson: Lesson

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Topic badge
            HStack(spacing: 6) {
                Image(systemName: lesson.topic.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(lesson.topic.rawValue)
                    .font(AppFont.microBold)
            }
            .foregroundColor(lesson.topic.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(lesson.topic.color.opacity(0.1))
            .clipShape(Capsule())

            // Title
            Text(lesson.title)
                .font(AppFont.serifBold(16))
                .foregroundColor(.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Promise
            Text(lesson.promise)
                .font(AppFont.caption)
                .foregroundColor(.mist)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Read time
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text("\(lesson.readMinutes) min read")
                    .font(AppFont.microBold)
            }
            .foregroundColor(.mist)
        }
        .padding(18)
        .frame(width: 220, height: 190)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.border, lineWidth: 1)
        )
        .shadow(color: Color.ink.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Topic Chip

struct TopicChip: View {
    let topic: LessonTopic
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: topic.icon)
                .font(.system(size: 12, weight: .medium))
            Text(topic.rawValue)
                .font(AppFont.microBold)
        }
        .foregroundColor(isSelected ? .paper : topic.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isSelected ? topic.color : topic.color.opacity(0.1))
        .clipShape(Capsule())
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - Lesson Row

struct LessonRow: View {
    let lesson: Lesson

    var body: some View {
        HStack(spacing: 14) {
            // Color dot
            Circle()
                .fill(lesson.topic.color)
                .frame(width: 10, height: 10)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(AppFont.bodyBold)
                    .foregroundColor(.ink)
                    .lineLimit(2)
                Text(lesson.promise)
                    .font(AppFont.caption)
                    .foregroundColor(.mist)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.border)
                Text("\(lesson.readMinutes)m")
                    .font(AppFont.microBold)
                    .foregroundColor(.mist)
            }
        }
        .padding(16)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Lesson Detail View

struct LessonDetailView: View {
    let lesson: Lesson
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Topic badge ───────────────────────────────────
                    HStack(spacing: 6) {
                        Image(systemName: lesson.topic.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(lesson.topic.rawValue)
                            .font(AppFont.microBold)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text("\(lesson.readMinutes) min read")
                                .font(AppFont.microBold)
                        }
                        .foregroundColor(.mist)
                    }
                    .foregroundColor(lesson.topic.color)
                    .padding(.bottom, 16)

                    // ── Title ─────────────────────────────────────────
                    Text(lesson.title)
                        .font(AppFont.serif(26))
                        .foregroundColor(.ink)
                        .padding(.bottom, 10)

                    // ── Promise ───────────────────────────────────────
                    Text(lesson.promise)
                        .font(AppFont.body)
                        .foregroundColor(.mist)
                        .padding(.bottom, 28)

                    // ── Divider ───────────────────────────────────────
                    Rectangle()
                        .fill(Color.border)
                        .frame(height: 1)
                        .padding(.bottom, 28)

                    // ── Body ──────────────────────────────────────────
                    Text(lesson.bodyText)
                        .font(AppFont.body)
                        .foregroundColor(.ink)
                        .lineSpacing(6)
                        .padding(.bottom, 32)

                    // ── Key Takeaways ─────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Key Takeaways")
                            .font(AppFont.serifBold(17))
                            .foregroundColor(.ink)
                            .padding(.bottom, 16)

                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(lesson.keyTakeaways.enumerated()), id: \.offset) { i, takeaway in
                                HStack(alignment: .top, spacing: 12) {
                                    // Number badge
                                    Text("\(i + 1)")
                                        .font(AppFont.microBold())
                                        .foregroundColor(lesson.topic.color)
                                        .frame(width: 22, height: 22)
                                        .background(lesson.topic.color.opacity(0.1))
                                        .clipShape(Circle())
                                        .padding(.top, 1)

                                    Text(takeaway)
                                        .font(AppFont.body())
                                        .foregroundColor(.ink)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 32)

                    // ── Action Button ─────────────────────────────────
                    if let actionLabel = lesson.actionLabel {
                        Button {
                            dismiss()
                            // Deep link back to plan tab — handled by parent TabView
                        } label: {
                            HStack(spacing: 8) {
                                Text(actionLabel)
                                    .font(AppFont.ctaButton())
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.sage, Color.sage.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.bottom, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
            .background(Color.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.mist)
                    }
                }
            }
        }
    }
}

// MARK: - AppFont helpers (add if not already in your Theme)
// These are convenience extensions — if you already have these in AppFont, delete this block.

extension AppFont {
    static func serifBold(_ size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size)
    }
}

