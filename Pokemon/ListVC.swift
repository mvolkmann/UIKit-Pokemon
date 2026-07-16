import UIKit

class ListVC: UITableViewController {
    private static let listBaseURL =
        URL(string: "https://pokeapi.co/api/v2/pokemon")!
    private static let listInitialURL =
        URL(string: "\(listBaseURL)?limit=100")!
    private static let rowHeight = 56.0

    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private var loadedPokemon: [Pokemon] = []
    private var nextPageURL: URL?
    private var selectedPokemon: Pokemon?

    // Sets up the list view and starts the initial Pokemon load.
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pokémon" // displayed at top of table
        tableView.rowHeight = Self.rowHeight + 12 // padding
        configureLoadingView()
        loadInitialPokemon()
    }

    // Adds newly fetched Pokemon to the table view.
    private func appendPokemon(_ newPokemon: [Pokemon]) {
        guard !newPokemon.isEmpty else { return }

        let startIndex = loadedPokemon.count
        loadedPokemon.append(contentsOf: newPokemon)

        let indexPaths = (startIndex ..< loadedPokemon.count).map {
            IndexPath(row: $0, section: 0)
        }
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    // Creates the loading view that is displayed while
    // the initial list of Pokemon data is being fetched.
    private func configureLoadingView() {
        let loadingLabel = UILabel()
        loadingLabel.text = "Loading Pokémon"

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.frame = CGRect(
            x: 0,
            y: 0,
            width: tableView.bounds.width,
            height: Self.rowHeight
        )

        let topSpacer = UIView()
        let bottomSpacer = UIView()

        let loadingStack = UIStackView(arrangedSubviews: [
            topSpacer,
            loadingLabel,
            loadingIndicator,
            bottomSpacer
        ])
        loadingStack.axis = .vertical
        loadingStack.alignment = .center
        loadingStack.spacing = 12
        loadingStack.frame = tableView.bounds
        loadingStack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bottomSpacer.heightAnchor.constraint(equalTo: topSpacer.heightAnchor)
            .isActive = true

        tableView.backgroundView = loadingStack
    }

    // Fetches and decodes a paged response from the Pokemon API.
    private func fetchPokemonList(from url: URL) async throws -> [Pokemon] {
        let (data, response) = try await URLSession.shared.data(from: url)
        try Self.validate(response)

        let listResponse = try JSONDecoder().decode(
            PokemonListResponse.self,
            from: data
        )

        if let next = listResponse.next {
            nextPageURL = URL(string: next)
        } else {
            nextPageURL = nil
        }

        return listResponse.results.map { item in
            Pokemon(id: item.id, name: item.name)
        }
    }

    // Fetches detail data for a single Pokemon.
    private func fetchPokemonDetail(for pokemon: Pokemon) async throws
        -> PokemonDetailResponse {
        let detailURL = ListVC.listBaseURL.appendingPathComponent(
            "\(pokemon.id)"
        )
        let (data, response) = try await URLSession.shared.data(from: detailURL)
        try Self.validate(response)

        let detail = try JSONDecoder().decode(
            PokemonDetailResponse.self,
            from: data
        )
        return detail
    }

    // Loads the first page of Pokemon and refreshes the table.
    private func loadInitialPokemon() {
        setLoading(true)
        Task {
            do {
                loadedPokemon =
                    try await fetchPokemonList(from: ListVC.listInitialURL)

                // Sleep to ensure that the loading indicator is displayed
                // even if the data is fetched quickly.
                try? await Task.sleep(for: .seconds(1))

                setLoading(false)
                tableView.reloadData()
            } catch {
                setLoading(false)
                showError(error)
            }
        }
    }

    // Loads more Pokemon if available.
    private func loadMorePokemon() {
        guard let url = nextPageURL else { return }

        setLoadingMore(true)
        Task {
            defer { setLoadingMore(false) }
            do {
                let pokemon = try await fetchPokemonList(from: url)
                appendPokemon(pokemon)
            } catch {
                nextPageURL = nil // so we don't try again to get more
                showError(error)
            }
        }
    }

    // Shows or hides the loading indicator in tableView.
    private func setLoading(_ isLoading: Bool) {
        tableView.backgroundView?.isHidden = !isLoading
        isLoading ?
            loadingIndicator.startAnimating() :
            loadingIndicator.stopAnimating()
    }

    // Shows or hides the loading indicator as the table footer.
    private func setLoadingMore(_ isLoading: Bool) {
        tableView.tableFooterView = isLoading ? loadingIndicator : nil
        isLoading ?
            loadingIndicator.startAnimating() :
            loadingIndicator.stopAnimating()
    }

    // Displays an alert that describes an error.
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Unable to Load Pokemon",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // Confirms that a URL response has a successful HTTP status code.
    private static func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // Returns the number of Pokemon rows currently loaded.
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        loadedPokemon.count
    }

    // Creates and configures a table cell for a Pokemon row.
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let pokemon = loadedPokemon[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "PokemonCell",
            for: indexPath
        ) as? PokemonCell else {
            return UITableViewCell()
        }

        cell.configure(with: pokemon)
        cell.accessoryType = .disclosureIndicator

        if let imageURL = pokemon.imageURL {
            loadThumbnail(
                from: imageURL,
                in: cell,
                pokemonID: pokemon.id
            )
        }

        return cell
    }

    // Downloads a thumbnail image for a Pokemon cell.
    private func loadThumbnail(
        from url: URL,
        in cell: PokemonCell,
        pokemonID: String
    ) {
        Task {
            let image: UIImage?

            do {
                let (data, response) = try await URLSession.shared
                    .data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200 ... 299).contains(httpResponse.statusCode),
                      let fetchedImage = UIImage(data: data) else {
                    return
                }
                image = fetchedImage
            } catch {
                image = UIImage(systemName: "exclamationmark.triangle")
            }

            // UIKit views must be updated on the main actor.
            await MainActor.run {
                guard let indexPath = tableView.indexPath(for: cell),
                      loadedPokemon[indexPath.row].id == pokemonID else {
                    return
                }
                cell.thumbnailImageView.image = image
            }
        }
    }

    // Starts loading the next page when the final row appears.
    override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard indexPath.row == loadedPokemon.count - 1 else { return }
        loadMorePokemon()
    }

    // Loads detail data and opens the detail screen for the selected Pokemon.
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        let aPokemon = loadedPokemon[indexPath.row]

        Task {
            do {
                let detail = try await fetchPokemonDetail(for: aPokemon)
                selectedPokemon = aPokemon.withDetail(detail)
                performSegue(withIdentifier: "ShowPokemonDetail", sender: self)
            } catch {
                showError(error)
            }
        }

        // Deselect the row so when the user returns to the list view,
        // it is no longer selected.
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // Allows the detail segue only after detail data has been loaded.
    override func shouldPerformSegue(
        withIdentifier identifier: String,
        sender: Any?
    ) -> Bool {
        guard identifier == "ShowPokemonDetail" else { return true }
        return selectedPokemon != nil
    }

    // Passes the selected Pokemon to the detail view controller.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowPokemonDetail",
              let detailViewController = segue
              .destination as? DetailVC else {
            return
        }

        detailViewController.pokemon = selectedPokemon
        selectedPokemon = nil
    }
}
