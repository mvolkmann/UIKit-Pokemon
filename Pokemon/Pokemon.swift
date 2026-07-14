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
    let imagePath: String?
    let types: [String]

    var displayName: String {
        name.capitalized
    }

    var listDisplayName: String {
        "#\(id) \(displayName)"
    }

    var imageURL: URL? {
        guard let imagePath else { return nil }
        return URL(string: imagePath)
    }

    var typeNames: [String] {
        types.map { $0.capitalized }
    }

    enum CodingKeys: CodingKey {
        case id
        case name
        case sprites
        case types
    }

    private struct Sprites: Decodable {
        let frontDefault: String?

        enum CodingKeys: String, CodingKey {
            case frontDefault = "front_default"
        }
    }

    private struct TypeSlot: Decodable {
        let type: PokemonType
    }

    private struct PokemonType: Decodable {
        let name: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        let sprites = try container.decode(Sprites.self, forKey: .sprites)
        imagePath = sprites.frontDefault

        let typeSlots = try container.decode([TypeSlot].self, forKey: .types)
        types = typeSlots.map { $0.type.name }
    }
}
