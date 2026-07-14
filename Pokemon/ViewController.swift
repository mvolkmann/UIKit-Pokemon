import UIKit

struct PokemonListResponse: Decodable {
    let count: Int
    let next: String?
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

class ViewController: UITableViewController {
    private let pageSize = 100
    private let pokemonListBaseURL =
        URL(string: "https://pokeapi.co/api/v2/pokemon")!
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadingMoreIndicator = UIActivityIndicatorView(style: .medium)
    private let loadingLabel = UILabel()
    private var pokemonByName: [String: Pokemon] = [:]
    private var pokemon: [Pokemon] = []
    private var nextOffset = 0
    private var totalPokemonCount: Int?
    private var isLoadingInitialPage = false
    private var isLoadingMore = false

    private var hasMorePokemon: Bool {
        guard let totalPokemonCount else { return true }
        return pokemon.count < totalPokemonCount
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pokemon"
        tableView.rowHeight = 68
        tableView.estimatedRowHeight = 68
        configureLoadingView()
        loadPokemon()
    }

    private func configureLoadingView() {
        loadingLabel.text = "Loading Pokemon"
        loadingLabel.font = .preferredFont(forTextStyle: .body)
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.adjustsFontForContentSizeCategory = true

        let loadingStack = UIStackView(arrangedSubviews: [
            loadingLabel,
            loadingIndicator
        ])
        loadingStack.axis = .vertical
        loadingStack.alignment = .center
        loadingStack.spacing = 12
        loadingStack.translatesAutoresizingMaskIntoConstraints = false

        let loadingView = UIView()
        loadingView.addSubview(loadingStack)
        NSLayoutConstraint.activate([
            loadingStack.centerXAnchor
                .constraint(equalTo: loadingView.centerXAnchor),
            loadingStack.centerYAnchor
                .constraint(equalTo: loadingView.centerYAnchor)
        ])
        tableView.backgroundView = loadingView

        loadingMoreIndicator.hidesWhenStopped = true
        loadingMoreIndicator.frame = CGRect(
            x: 0,
            y: 0,
            width: tableView.bounds.width,
            height: 56
        )
    }

    private func setLoading(_ isLoading: Bool) {
        tableView.backgroundView?.isHidden = !isLoading
        isLoading ? loadingIndicator.startAnimating() : loadingIndicator
            .stopAnimating()
    }

    private func loadPokemon() {
        guard !isLoadingInitialPage else { return }

        isLoadingInitialPage = true
        setLoading(true)
        Task {
            defer {
                isLoadingInitialPage = false
                setLoading(false)
            }

            do {
                let page = try await fetchPokemonPage(offset: 0)
                totalPokemonCount = page.totalCount
                nextOffset = page.nextOffset ?? page.pokemon.count
                pokemon = page.pokemon
                print(pokemon)
                pokemonByName = Dictionary(
                    uniqueKeysWithValues: page.pokemon.map { ($0.name, $0) }
                )
                tableView.reloadData()
            } catch {
                showError(error)
            }
        }
    }

    private func loadMorePokemonIfNeeded() {
        guard hasMorePokemon,
              !isLoadingInitialPage,
              !isLoadingMore else {
            return
        }

        isLoadingMore = true
        setLoadingMore(true)
        let offset = nextOffset
        Task {
            defer {
                isLoadingMore = false
                setLoadingMore(false)
            }

            do {
                let page = try await fetchPokemonPage(offset: offset)
                totalPokemonCount = page.totalCount
                nextOffset = page.nextOffset ?? pokemon.count + page.pokemon
                    .count
                appendPokemon(page.pokemon)
            } catch {
                showError(error)
            }
        }
    }

    private func setLoadingMore(_ isLoading: Bool) {
        tableView.tableFooterView = isLoading ? loadingMoreIndicator : nil
        isLoading ? loadingMoreIndicator.startAnimating() : loadingMoreIndicator
            .stopAnimating()
    }

    private func appendPokemon(_ newPokemon: [Pokemon]) {
        guard !newPokemon.isEmpty else { return }

        let startIndex = pokemon.count
        pokemon.append(contentsOf: newPokemon)
        newPokemon.forEach { pokemonByName[$0.name] = $0 }

        let indexPaths = (startIndex ..< pokemon.count).map {
            IndexPath(row: $0, section: 0)
        }
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    private func fetchPokemonPage(offset: Int) async throws -> (
        pokemon: [Pokemon],
        totalCount: Int,
        nextOffset: Int?
    ) {
        let listURL = try makePokemonListURL(offset: offset)
        let (data, response) = try await URLSession.shared.data(from: listURL)
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

        return (
            pokemon.sorted { $0.id < $1.id },
            listResponse.count,
            Self.offset(from: listResponse.next)
        )
    }

    private func makePokemonListURL(offset: Int) throws -> URL {
        var components = URLComponents(
            url: pokemonListBaseURL,
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "\(pageSize)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]

        guard let url = components?.url else { throw URLError(.badURL) }
        return url
    }

    private static func offset(from nextURLString: String?) -> Int? {
        guard let nextURLString,
              let url = URL(string: nextURLString),
              let components = URLComponents(
                  url: url,
                  resolvingAgainstBaseURL: false
              ),
              let offset = components.queryItems?
              .first(where: { $0.name == "offset" })?.value else {
            return nil
        }

        return Int(offset)
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
        let pokemon = pokemon[indexPath.row]
        configure(cell, with: pokemon)
        cell.accessoryType = .disclosureIndicator

        if let imageURL = pokemon.imageURL,
           let thumbnailImageView = cell.contentView.viewWithTag(1002)
           as? UIImageView {
            loadThumbnail(
                from: imageURL,
                for: thumbnailImageView,
                in: cell,
                pokemonID: pokemon.id
            )
        }

        return cell
    }

    private func configure(_ cell: UITableViewCell, with pokemon: Pokemon) {
        cell.contentConfiguration = nil

        let idLabel: UILabel
        let thumbnailImageView: UIImageView
        let nameLabel: UILabel

        if let existingIDLabel = cell.contentView.viewWithTag(1001) as? UILabel,
           let existingThumbnailImageView = cell.contentView.viewWithTag(1002)
           as? UIImageView,
           let existingNameLabel = cell.contentView.viewWithTag(1003) as? UILabel {
            idLabel = existingIDLabel
            thumbnailImageView = existingThumbnailImageView
            nameLabel = existingNameLabel
        } else {
            idLabel = UILabel()
            idLabel.tag = 1001
            idLabel.font = .preferredFont(forTextStyle: .body)
            idLabel.adjustsFontForContentSizeCategory = true
            idLabel.setContentHuggingPriority(.required, for: .horizontal)

            thumbnailImageView = UIImageView()
            thumbnailImageView.tag = 1002
            thumbnailImageView.contentMode = .scaleAspectFit
            thumbnailImageView.tintColor = .secondaryLabel
            thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 56)
                .isActive = true
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 56)
                .isActive = true

            nameLabel = UILabel()
            nameLabel.tag = 1003
            nameLabel.font = .preferredFont(forTextStyle: .body)
            nameLabel.adjustsFontForContentSizeCategory = true

            let stackView = UIStackView(arrangedSubviews: [
                idLabel,
                thumbnailImageView,
                nameLabel
            ])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = 8
            stackView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(
                    equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor
                ),
                stackView.trailingAnchor.constraint(
                    equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor
                ),
                stackView.topAnchor.constraint(
                    equalTo: cell.contentView.layoutMarginsGuide.topAnchor
                ),
                stackView.bottomAnchor.constraint(
                    equalTo: cell.contentView.layoutMarginsGuide.bottomAnchor
                )
            ])
        }

        idLabel.text = "#\(pokemon.id)"
        thumbnailImageView.image = UIImage(systemName: "photo")
        nameLabel.text = pokemon.displayName
    }

    private func loadThumbnail(
        from url: URL,
        for thumbnailImageView: UIImageView,
        in cell: UITableViewCell,
        pokemonID: Int
    ) {
        Task { [weak self, weak thumbnailImageView, weak cell] in
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200 ... 299).contains(httpResponse.statusCode),
                      let image = UIImage(data: data) else {
                    return
                }

                self?.setThumbnail(
                    image,
                    in: thumbnailImageView,
                    cell: cell,
                    pokemonID: pokemonID
                )
            } catch {
                self?.setThumbnail(
                    UIImage(systemName: "exclamationmark.triangle"),
                    in: thumbnailImageView,
                    cell: cell,
                    pokemonID: pokemonID
                )
            }
        }
    }

    @MainActor
    private func setThumbnail(
        _ image: UIImage?,
        in thumbnailImageView: UIImageView?,
        cell: UITableViewCell?,
        pokemonID: Int
    ) {
        guard let thumbnailImageView,
              let cell,
              let indexPath = tableView.indexPath(for: cell),
              pokemon.indices.contains(indexPath.row),
              pokemon[indexPath.row].id == pokemonID else {
            return
        }

        thumbnailImageView.image = image
    }

    override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard indexPath.row == pokemon.count - 1 else { return }
        loadMorePokemonIfNeeded()
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
