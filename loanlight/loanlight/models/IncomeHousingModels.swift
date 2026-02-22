import Foundation

// MARK: - Job Offer
// Maps to: job_offer_models.py

struct JobOfferIn: Encodable {
    let baseSalary: Decimal
    let bonus: Decimal?
    let state: String              // 2-letter, e.g. "MA"

    enum CodingKeys: String, CodingKey {
        case baseSalary = "base_salary"
        case bonus
        case state
    }
}

struct JobOfferOut: Decodable, Identifiable {
    let id: UUID
    let baseSalary: Decimal
    let bonus: Decimal?
    let state: String
    let estimatedTakeHomeMonthly: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case baseSalary               = "base_salary"
        case bonus
        case state
        case estimatedTakeHomeMonthly = "estimated_take_home_monthly"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func d(_ k: CodingKeys) -> Decimal {
            if let s = try? c.decode(String.self, forKey: k), let v = Decimal(string: s) { return v }
            return (try? c.decode(Decimal.self, forKey: k)) ?? 0
        }
        id                       = try c.decode(UUID.self, forKey: .id)
        state                    = try c.decode(String.self, forKey: .state)
        baseSalary               = d(.baseSalary)
        let bonusStr             = try? c.decode(String.self, forKey: .bonus)
        bonus                    = bonusStr.flatMap { Decimal(string: $0) }
        estimatedTakeHomeMonthly = d(.estimatedTakeHomeMonthly)
    }
}

// MARK: - Housing
// Maps to: housing_models.py

struct HousingIn: Encodable {
    let city: String
    let state: String              // 2-letter
    let bedroomCount: Int          // 0 = studio
    let housingType: String        // default "apartment"

    enum CodingKeys: String, CodingKey {
        case city
        case state
        case bedroomCount  = "bedroom_count"
        case housingType   = "housing_type"
    }
}

struct HousingOut: Decodable, Identifiable {
    let id: UUID
    let city: String
    let state: String
    let bedroomCount: Int
    let housingType: String
    let hudEstimatedRentMonthly: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case city
        case state
        case bedroomCount            = "bedroom_count"
        case housingType             = "housing_type"
        case hudEstimatedRentMonthly = "hud_estimated_rent_monthly"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self, forKey: .id)
        city         = try c.decode(String.self, forKey: .city)
        state        = try c.decode(String.self, forKey: .state)
        bedroomCount = try c.decode(Int.self, forKey: .bedroomCount)
        housingType  = try c.decode(String.self, forKey: .housingType)
        let rentStr  = try? c.decode(String.self, forKey: .hudEstimatedRentMonthly)
        hudEstimatedRentMonthly = rentStr.flatMap { Decimal(string: $0) }
            ?? (try? c.decode(Decimal.self, forKey: .hudEstimatedRentMonthly)) ?? 0
    }
}
