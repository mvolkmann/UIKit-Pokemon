import UIKit

final class PokemonCell: UITableViewCell {
    private static let thumbnailSize = 56.0

    let thumbnailImageView = UIImageView()

    private let idLabel = UILabel()
    private let nameLabel = UILabel()
    private var didConfigureLayout = false

    func configure(with pokemon: Pokemon) {
        configureLayoutIfNeeded()
        contentConfiguration = nil
        idLabel.text = "#\(pokemon.id)"
        thumbnailImageView.image = nil
        nameLabel.text = pokemon.name.capitalized
    }

    private func configureLayoutIfNeeded() {
        guard !didConfigureLayout else { return }
        didConfigureLayout = true

        idLabel.font = .preferredFont(forTextStyle: .body)
        idLabel.adjustsFontForContentSizeCategory = true
        idLabel.setContentHuggingPriority(.required, for: .horizontal)

        thumbnailImageView.contentMode = .scaleAspectFit
        thumbnailImageView.tintColor = .secondaryLabel
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

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
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            thumbnailImageView.widthAnchor
                .constraint(equalToConstant: Self.thumbnailSize),
            thumbnailImageView.heightAnchor
                .constraint(equalToConstant: Self.thumbnailSize),
            stackView.leadingAnchor.constraint(
                equalTo: contentView.layoutMarginsGuide.leadingAnchor
            ),
            stackView.trailingAnchor.constraint(
                equalTo: contentView.layoutMarginsGuide.trailingAnchor
            ),
            stackView.topAnchor.constraint(
                equalTo: contentView.layoutMarginsGuide.topAnchor
            ),
            stackView.bottomAnchor.constraint(
                equalTo: contentView.layoutMarginsGuide.bottomAnchor
            )
        ])
    }
}
