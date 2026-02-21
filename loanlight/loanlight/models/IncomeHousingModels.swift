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
    /// Computed by backend — this is what drives the plan screen
    let estimatedTakeHomeMonthly: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case baseSalary                 = "base_salary"
        case bonus
        case state
        case estimatedTakeHomeMonthly   = "estimated_take_home_monthly"
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
    /// Computed by HUD FMR API — what drives the plan screen
    let hudEstimatedRentMonthly: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case city
        case state
        case bedroomCount            = "bedroom_count"
        case housingType             = "housing_type"
        case hudEstimatedRentMonthly = "hud_estimated_rent_monthly"
    }
}
