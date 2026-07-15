import Foundation

struct PokemonItem: Decodable {
    let name: String
    let url: String

    var id: String {
        String(url.split(separator: "/").last!)
    }
}

struct PokemonResponse: Decodable {
    let count: Int
    let next: String?
    let results: [PokemonItem]
}

struct Pokemon {
    let id: String
    let name: String
    let imagePath: String
    let types: [String]

    init(id: String, name: String, imagePath: String, types: [String] = []) {
        self.id = id
        self.name = name
        self.imagePath = imagePath
        self.types = types
    }

    init?(item: PokemonItem) {
        self.init(
            id: item.id,
            name: item.name,
            imagePath: Self.imagePath(for: item.id)
        )
    }

    var displayName: String {
        name.capitalized
    }

    var imageURL: URL? {
        URL(string: imagePath)
    }

    var typeNames: [String] {
        types.map { $0.capitalized }
    }

    func withTypes(_ types: [String]) -> Pokemon {
        Pokemon(id: id, name: name, imagePath: imagePath, types: types)
    }

    private static func imagePath(for id: String) -> String {
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
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
