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
struct PokemonResponse: Decodable {
    let count: Int
    let next: String?
    let results: [PokemonItem]
}

struct Pokemon {
    let id: String
    let name: String
    let types: [String] // loaded by detail request

    init(id: String, name: String, types: [String] = []) {
        self.id = id
        self.name = name
        self.types = types
    }

    init?(item: PokemonItem) {
        self.init(id: item.id, name: item.name)
    }

    var imagePath: String {
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
    }

    var imageURL: URL? {
        URL(string: imagePath)
    }

    var typeNames: String {
        types.map { $0.capitalized }.joined(separator: ", ")
    }

    func withTypes(_ types: [String]) -> Pokemon {
        Pokemon(id: id, name: name, types: types)
    }
}

struct PokemonDetailResponse: Decodable {
    let types: [String]

    private struct TypeSlot: Decodable {
        let type: PokemonType
    }

    private struct PokemonType: Decodable {
        let name: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeSlots = try container.decode([TypeSlot].self, forKey: .types)
        types = typeSlots.map { $0.type.name }
    }

    private enum CodingKeys: CodingKey {
        case types
    }
}
