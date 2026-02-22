import Foundation

// MARK: - Job Offer

// Request: the API expects base_salary and bonus as JSON numbers (not strings)
struct JobOfferIn: Encodable {
    let baseSalary: Decimal
    let bonus: Decimal?
    let state: String

    enum CodingKeys: String, CodingKey {
        case baseSalary = "base_salary"
        case bonus
        case state
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        // Encode Decimals as JSON numbers (API requires numbers, not strings)
        try c.encode(NSDecimalNumber(decimal: baseSalary).doubleValue, forKey: .baseSalary)
        if let bonus = bonus {
            try c.encode(NSDecimalNumber(decimal: bonus).doubleValue, forKey: .bonus)
        } else {
            try c.encodeNil(forKey: .bonus)
        }
        try c.encode(state, forKey: .state)
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
        let c                    = try decoder.container(keyedBy: CodingKeys.self)
        id                       = try c.decode(UUID.self, forKey: .id)
        baseSalary               = try c.decodeDecimalString(forKey: .baseSalary)
        bonus                    = try c.decodeDecimalStringIfPresent(forKey: .bonus)
        state                    = try c.decode(String.self, forKey: .state)
        estimatedTakeHomeMonthly = try c.decodeDecimalString(forKey: .estimatedTakeHomeMonthly)
    }
}

// MARK: - Housing

// Request: bedroom_count is Int (fine), no Decimal fields in HousingIn
struct HousingIn: Encodable {
    let city: String
    let state: String
    let bedroomCount: Int
    let housingType: String

    enum CodingKeys: String, CodingKey {
        case city
        case state
        case bedroomCount = "bedroom_count"
        case housingType  = "housing_type"
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
        let c                   = try decoder.container(keyedBy: CodingKeys.self)
        id                      = try c.decode(UUID.self, forKey: .id)
        city                    = try c.decode(String.self, forKey: .city)
        state                   = try c.decode(String.self, forKey: .state)
        bedroomCount            = try c.decode(Int.self, forKey: .bedroomCount)
        housingType             = try c.decode(String.self, forKey: .housingType)
        hudEstimatedRentMonthly = try c.decodeDecimalString(forKey: .hudEstimatedRentMonthly)
    }
}
