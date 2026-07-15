import UIKit

class PokemonDetailViewController: UIViewController {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var typesLabel: UILabel!

    var pokemon: Pokemon?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    private func configureView() {
        guard let pokemon else { return }

        title = pokemon.name.capitalized
        typesLabel.text = pokemon.typeNames.joined(separator: ", ")
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .secondaryLabel

        guard let imageURL = pokemon.imageURL else { return }
        Task {
            await loadImage(from: imageURL)
        }
    }

    private func loadImage(from url: URL) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                return
            }
            imageView.image = image
        } catch {
            imageView.image = UIImage(systemName: "exclamationmark.triangle")
        }
    }
}
