import UIKit

// This is the view controller used by the detail screen.
class DetailVC: UIViewController {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var typesLabel: UILabel!
    @IBOutlet private var heightLabel: UILabel!
    @IBOutlet private var weightLabel: UILabel!

    var pokemon: Pokemon?

    // Configures the detail screen after the view has loaded.
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    // Displays the selected Pokemon image and detail data.
    private func configureView() {
        guard let pokemon else { return }

        title = pokemon.name.capitalized
        typesLabel.text = pokemon.typeNames
        heightLabel.text = pokemon.heightDescription
        weightLabel.text = pokemon.weightDescription
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .secondaryLabel

        guard let imageURL = pokemon.imageURL else { return }
        Task {
            await loadImage(from: imageURL)
        }
    }

    // Downloads and displays the full-size Pokemon image.
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
