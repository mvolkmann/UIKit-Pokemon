import Foundation

struct PokemonItem: Decodable {
    let name: String
    let url: String
}

struct PokemonResponse: Decodable {
    let count: Int
    let next: String?
    let results: [PokemonItem]
}

struct Pokemon: Decodable {
    let id: Int
    let name: String
    let sprites: PokemonSprites
    let types: [String]

    var displayName: String {
        name.capitalized
    }

    var listDisplayName: String {
        "#\(id) \(displayName)"
    }

    var imageURL: URL? {
        guard let imagePath = sprites.frontDefault else { return nil }
        return URL(string: imagePath)
    }

    var typeNames: [String] {
        types.map { $0.capitalized }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sprites
        case types
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sprites = try container.decode(PokemonSprites.self, forKey: .sprites)

        let typeSlots = try container.decode([PokemonTypeResponse].self, forKey: .types)
        types = typeSlots.map { $0.type.name }
    }
}

struct PokemonSprites: Decodable {
    let frontDefault: String?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

private struct PokemonTypeResponse: Decodable {
    let type: PokemonNamedResource
}

private struct PokemonNamedResource: Decodable {
    let name: String
}
