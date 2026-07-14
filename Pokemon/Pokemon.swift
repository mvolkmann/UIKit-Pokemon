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

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sprites
        case types
    }

    enum SpriteCodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }

    enum TypeSlotCodingKeys: String, CodingKey {
        case type
    }

    enum TypeCodingKeys: String, CodingKey {
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let spritesContainer = try container.nestedContainer(keyedBy: SpriteCodingKeys.self, forKey: .sprites)
        imagePath = try spritesContainer.decodeIfPresent(String.self, forKey: .frontDefault)

        var typeSlotsContainer = try container.nestedUnkeyedContainer(forKey: .types)
        var typeNames: [String] = []

        while !typeSlotsContainer.isAtEnd {
            let typeSlotContainer = try typeSlotsContainer.nestedContainer(keyedBy: TypeSlotCodingKeys.self)
            let typeContainer = try typeSlotContainer.nestedContainer(keyedBy: TypeCodingKeys.self, forKey: .type)
            let typeName = try typeContainer.decode(String.self, forKey: .name)
            typeNames.append(typeName)
        }

        types = typeNames
    }
}
