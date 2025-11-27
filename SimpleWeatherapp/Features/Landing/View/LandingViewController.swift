import UIKit

final class LandingViewController: UIViewController {

    // MARK: - Outlets (connect these in storyboard)
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var getStartedButton: UIButton!

    // MARK: - Private UI
    private let gradientLayer = CAGradientLayer()
    private let iconBackgroundView = UIView()

    private let featuresContainer = UIView()
    private let featuresStackView = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Landing hides nav bar
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupGradientBackground()
        setupHeroSection()
        setupCardAndButtonLayout()
        setupFeaturesContent()
        styleGetStartedButton()
        setupButtonAnimationTargets()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds

        // Card shadow
        featuresContainer.layer.cornerRadius = 24
        featuresContainer.layer.masksToBounds = false
        featuresContainer.layer.shadowColor = UIColor.black.cgColor
        featuresContainer.layer.shadowOpacity = 0.18
        featuresContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        featuresContainer.layer.shadowRadius = 20
    }

    // MARK: - Background

    private func setupGradientBackground() {
        gradientLayer.colors = [
            UIColor.systemBlue.cgColor,
            UIColor.systemTeal.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        gradientLayer.frame      = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    // MARK: - Hero (sun + title + subtitle)

    private func setupHeroSection() {
        // Soft glowing circle behind the sun
        view.insertSubview(iconBackgroundView, belowSubview: iconImageView)
        iconBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconBackgroundView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
            iconBackgroundView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 140),
            iconBackgroundView.heightAnchor.constraint(equalTo: iconBackgroundView.widthAnchor)
        ])
        iconBackgroundView.layer.cornerRadius = 70
        iconBackgroundView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.18)
        iconBackgroundView.layer.shadowColor = UIColor.systemYellow.cgColor
        iconBackgroundView.layer.shadowOpacity = 0.6
        iconBackgroundView.layer.shadowOffset = .zero
        iconBackgroundView.layer.shadowRadius = 20

        // Big yellow sun icon
        let config = UIImage.SymbolConfiguration(pointSize: 72, weight: .bold)
        iconImageView.preferredSymbolConfiguration = config
        iconImageView.image = UIImage(systemName: "sun.max.fill")
        iconImageView.tintColor = .systemYellow

        // Title + subtitle
        titleLabel.text = "Simple Weather"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Track your favourite cities\nwith clean, beautiful forecasts."
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
    }

    // MARK: - Layout for card + button

    private func setupCardAndButtonLayout() {
        // ---- Card container ----
        featuresContainer.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        view.addSubview(featuresContainer)
        featuresContainer.translatesAutoresizingMaskIntoConstraints = false

        // ---- Button constraints (IMPORTANT: delete all button constraints in storyboard) ----
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Button at bottom
            getStartedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            getStartedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            getStartedButton.heightAnchor.constraint(equalToConstant: 48),
            getStartedButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 190),

            // Card above the button
            featuresContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            featuresContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            featuresContainer.bottomAnchor.constraint(equalTo: getStartedButton.topAnchor, constant: -24),
            featuresContainer.topAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.bottomAnchor, constant: 24)
        ])

        // ---- Stack inside card ----
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 12
        featuresStackView.alignment = .fill
        featuresStackView.distribution = .fill

        featuresContainer.addSubview(featuresStackView)
        featuresStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            featuresStackView.topAnchor.constraint(equalTo: featuresContainer.topAnchor, constant: 18),
            featuresStackView.bottomAnchor.constraint(equalTo: featuresContainer.bottomAnchor, constant: -18),
            featuresStackView.leadingAnchor.constraint(equalTo: featuresContainer.leadingAnchor, constant: 18),
            featuresStackView.trailingAnchor.constraint(equalTo: featuresContainer.trailingAnchor, constant: -18)
        ])
    }

    // MARK: - Fill card content

    private func setupFeaturesContent() {
        // Header
        let headerLabel = UILabel()
        headerLabel.text = "Why you'll love Simple Weather"
        headerLabel.textColor = .white
        headerLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        headerLabel.numberOfLines = 0
        featuresStackView.addArrangedSubview(headerLabel)
        featuresStackView.setCustomSpacing(14, after: headerLabel)

        // Three feature rows
        featuresStackView.addArrangedSubview(makeFeatureRow(
            iconName: "list.bullet",
            text: "Save multiple cities and switch between them instantly."
        ))
        featuresStackView.addArrangedSubview(makeFeatureRow(
            iconName: "arrow.clockwise",
            text: "Pull to refresh and get the latest live data."
        ))
        featuresStackView.addArrangedSubview(makeFeatureRow(
            iconName: "cloud.sun.fill",
            text: "Enjoy a clean layout with detailed conditions."
        ))
    }

    private func makeFeatureRow(iconName: String, text: String) -> UIStackView {
        let icon = UIImageView()
        icon.image = UIImage(systemName: iconName)
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = text
        label.textColor = UIColor.white.withAlphaComponent(0.95)
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0

        let hStack = UIStackView(arrangedSubviews: [icon, label])
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .center
        return hStack
    }

    // MARK: - Button styling

    private func styleGetStartedButton() {
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.setTitleColor(.systemBlue, for: .normal)
        getStartedButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        getStartedButton.backgroundColor = .white
        getStartedButton.layer.cornerRadius = 24
        getStartedButton.layer.masksToBounds = false

        // Arrow icon on the right
        let image = UIImage(systemName: "arrow.right.circle.fill")
        getStartedButton.setImage(image, for: .normal)
        getStartedButton.tintColor = .systemBlue

        // Image on the right side of text
        getStartedButton.semanticContentAttribute = .forceRightToLeft
        getStartedButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)

        // Shadow
        getStartedButton.layer.shadowColor = UIColor.black.cgColor
        getStartedButton.layer.shadowOpacity = 0.25
        getStartedButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        getStartedButton.layer.shadowRadius = 10

        // Ensure button is above the card
        view.bringSubviewToFront(getStartedButton)
    }

    private func setupButtonAnimationTargets() {
        getStartedButton.addTarget(self,
                                   action: #selector(buttonTouchDown),
                                   for: [.touchDown, .touchDragEnter])
        getStartedButton.addTarget(self,
                                   action: #selector(buttonTouchUp),
                                   for: [.touchUpInside, .touchDragExit, .touchCancel])
    }

    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.12) {
            self.getStartedButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
    }

    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.22,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut,
                       animations: {
            self.getStartedButton.transform = .identity
        }, completion: nil)
    }

    // MARK: - Actions

    @IBAction private func getStartedTapped(_ sender: UIButton) {
        // Show nav bar again for rest of the app
        navigationController?.setNavigationBarHidden(false, animated: false)

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let cityListVC = storyboard.instantiateViewController(
            withIdentifier: "CityListViewController"
        ) as? CityListViewController else {
            print("❌ Could not load CityListViewController. Check Storyboard ID & class.")
            return
        }

        navigationController?.pushViewController(cityListVC, animated: true)
    }
}
