import UIKit

struct PokemonListResponse: Decodable {
    let results: [PokemonListItem]
}

struct PokemonListItem: Decodable {
    let name: String
    let url: String
}

struct Pokemon: Decodable {
    let id: Int
    let name: String
    let sprites: PokemonSprites
    let types: [PokemonTypeSlot]

    var displayName: String {
        name.capitalized
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

class ViewController: UITableViewController {
    private let pokemonListURL =
        URL(string: "https://pokeapi.co/api/v2/pokemon?limit=100")!
    private var pokemonByName: [String: Pokemon] = [:]
    private var pokemon: [Pokemon] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pokemon"
        loadPokemon()
    }

    private func loadPokemon() {
        Task {
            do {
                let pokemon = try await fetchFirstPokemon()
                self.pokemon = pokemon
                self
                    .pokemonByName = Dictionary(
                        uniqueKeysWithValues: pokemon
                            .map { (
                                $0.name,
                                $0
                            ) }
                    )
                tableView.reloadData()
            } catch {
                showError(error)
            }
        }
    }

    private func fetchFirstPokemon() async throws -> [Pokemon] {
        let (data, response) = try await URLSession.shared
            .data(from: pokemonListURL)
        try Self.validate(response)

        let listResponse = try JSONDecoder().decode(
            PokemonListResponse.self,
            from: data
        )
        var pokemon: [Pokemon] = []
        for listItem in listResponse.results {
            guard let url = URL(string: listItem.url) else { continue }
            let (detailData, detailResponse) = try await URLSession.shared
                .data(from: url)
            try Self.validate(detailResponse)
            let detail = try JSONDecoder().decode(
                Pokemon.self,
                from: detailData
            )
            pokemon.append(detail)
        }

        return pokemon.sorted { $0.id < $1.id }
    }

    private static func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Unable to Load Pokemon",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        pokemon.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "PokemonCell",
            for: indexPath
        )
        var content = cell.defaultContentConfiguration()
        content.text = pokemon[indexPath.row].displayName
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowPokemonDetail",
              let detailViewController = segue
              .destination as? PokemonDetailViewController,
              let selectedIndexPath = tableView.indexPathForSelectedRow else {
            return
        }

        let selectedPokemon = pokemon[selectedIndexPath.row]
        detailViewController.pokemon = pokemonByName[selectedPokemon.name]
    }
}
