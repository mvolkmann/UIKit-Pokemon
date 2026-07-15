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
    let types: [String] // loaded by detail request; see withTypes method

    init(id: String, name: String, types: [String] = []) {
        self.id = id
        self.name = name
        self.types = types
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

    // Creates a new instance of the Pokemon struct
    // whose types property is set.
    func withTypes(_ types: [String]) -> Pokemon {
        Pokemon(id: id, name: name, types: types)
    }
}

struct PokemonDetailResponse: Decodable {
    let types: [String] // only property in the response we care about

    // Used in JSON decoding.
    private enum CodingKeys: CodingKey {
        case types
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
    }
}
