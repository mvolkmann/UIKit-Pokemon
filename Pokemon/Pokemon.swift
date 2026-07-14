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
    let types: [PokemonTypeSlot]

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
        types.map { $0.type.name.capitalized }
    }
}

struct PokemonSprites: Decodable {
    let frontDefault: String?

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct PokemonTypeSlot: Decodable {
    let slot: Int
    let type: PokemonNamedResource
}

struct PokemonNamedResource: Decodable {
    let name: String
}
