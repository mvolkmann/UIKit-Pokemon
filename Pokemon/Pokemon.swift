import Foundation

// Used by PokemonResponse.
struct PokemonItem: Decodable {
    let name: String
    let url: String

    // Computed from the URL last path part.
    var id: String {
        String(url.split(separator: "/").last!)
    }
}

// Matches JSON returned for a list of Pokemon.
struct PokemonListResponse: Decodable {
    let count: Int
    let next: String?
    let results: [PokemonItem]
}

struct Pokemon {
    // The id value is actually an Int, but in this app
    // there's no benefit to converting the String values to Int values.
    let id: String
    let name: String
    let types: [String] // loaded by detail request; see withDetail method
    let height: Int // loaded by detail request; unit is decimeters
    let weight: Int // loaded by detail request; unit is hectograms

    init(
        id: String,
        name: String,
        types: [String] = [],
        height: Int = 0,
        weight: Int = 0
    ) {
        self.id = id
        self.name = name
        self.types = types
        self.height = height
        self.weight = weight
    }

    init?(item: PokemonItem) {
        self.init(id: item.id, name: item.name)
    }

    // Computes the image URL from the Pokemon id.
    var imagePath: String {
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
    }

    var imageURL: URL? {
        URL(string: imagePath)
    }

    // Creates a string representation of the types array
    // for presenting in the UI.
    var typeNames: String {
        types.map { $0.capitalized }.joined(separator: ", ")
    }

    var heightDescription: String {
        guard height > 0 else { return "unknown" }
        return "\(height * 10) cm"
    }

    var weightDescription: String {
        guard weight > 0 else { return "unknown" }
        return "\(Double(weight) / 10.0) kg"
    }

    // Creates a new instance of the Pokemon struct
    // whose detail properties are set.
    func withDetail(_ detail: PokemonDetailResponse) -> Pokemon {
        Pokemon(
            id: id,
            name: name,
            types: detail.types,
            height: detail.height,
            weight: detail.weight
        )
    }
}

struct PokemonDetailResponse: Decodable {
    let types: [String]
    let height: Int
    let weight: Int

    // Used in JSON decoding.
    private enum CodingKeys: CodingKey {
        case types
        case height
        case weight
    }

    // Used in JSON decoding.
    private struct TypeSlot: Decodable {
        let type: PokemonType
    }

    // Used in JSON decoding.
    private struct PokemonType: Decodable {
        let name: String
    }

    // Sets the types property from Pokemon detail JSON data.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeSlots = try container.decode([TypeSlot].self, forKey: .types)
        types = typeSlots.map { $0.type.name }
        height = try container.decode(Int.self, forKey: .height)
        weight = try container.decode(Int.self, forKey: .weight)
    }
}
