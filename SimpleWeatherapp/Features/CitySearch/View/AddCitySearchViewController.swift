import UIKit

final class AddCitySearchViewController: UIViewController {

    // MARK: - Outlets (from storyboard)
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Callback back to city list
    /// CityListViewController sets this; we call it when user picks a city.
    var onCitySelected: ((String) -> Void)?

    // MARK: - Private properties

    /// Results from CitySearchService
    private var suggestions: [CitySuggestion] = []

    /// For debouncing the typing
    private var searchTask: DispatchWorkItem?

    /// API service (you already have this implemented)
    private let searchService = CitySearchService.shared

    /// Loader inside the text field (right side)
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    /// Label used for "start typing", "no results", "error" states
    private let stateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    /// Background gradient so this screen matches the rest of the app
    private let backgroundGradient = CAGradientLayer()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add City"
        view.backgroundColor = .systemTeal

        setupBackgroundGradient()
        setupTableView()
        setupSearchField()

        // Keyboard dismiss when you scroll
        tableView.keyboardDismissMode = .onDrag

        // Background state label (shows when there are no rows)
        tableView.backgroundView = stateLabel
        stateLabel.text = "Start typing a city name..."
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }

    // MARK: - Background

    private func setupBackgroundGradient() {
        backgroundGradient.colors = [
            UIColor.systemBlue.cgColor,
            UIColor.systemTeal.cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint   = CGPoint(x: 1, y: 1)
        backgroundGradient.frame      = view.bounds
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
    }

    private func setupSearchField() {
        searchTextField.placeholder = "Search city"
        searchTextField.borderStyle = .roundedRect
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        searchTextField.textColor = .label

        // loader on right side
        searchTextField.rightView = loadingIndicator
        searchTextField.rightViewMode = .always

        // listen to text changes
        searchTextField.addTarget(
            self,
            action: #selector(searchTextChanged(_:)),
            for: .editingChanged
        )
    }

    // MARK: - Loader

    private func setLoading(_ loading: Bool) {
        if loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    // MARK: - Search logic

    @objc private func searchTextChanged(_ textField: UITextField) {
        let query = (textField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Cancel previous pending search
        searchTask?.cancel()

        if query.isEmpty {
            // Clear list + UI when field is empty
            suggestions = []
            tableView.reloadData()
            setLoading(false)
            stateLabel.text = "Start typing a city name..."
            return
        }

        // Show "searching" state
        setLoading(true)
        stateLabel.text = "Searching…"

        // Debounce: wait a bit after user stops typing
        let work = DispatchWorkItem { [weak self] in
            self?.performSearch(query: query)
        }
        searchTask = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func performSearch(query: String) {
        searchService.searchCities(matching: query) { [weak self] result in
            guard let self = self else { return }

            // Stop loader no matter what
            self.setLoading(false)

            switch result {
            case .success(let cities):
                self.suggestions = cities
                self.tableView.reloadData()

                if cities.isEmpty {
                    self.stateLabel.text = "No cities found.\nTry a different spelling."
                } else {
                    self.stateLabel.text = nil
                }

            case .failure(let error):
                print("🔴 City search failed:", error)
                self.suggestions = []
                self.tableView.reloadData()
                self.stateLabel.text = "Something went wrong.\nPlease try again."
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension AddCitySearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "CitySuggestionCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellId)

        let suggestion = suggestions[indexPath.row]

        // Main city name bigger
        cell.textLabel?.text = suggestion.name
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        cell.textLabel?.textColor = .white

        // Subtitle: "State, Country" or just "Country"
        cell.detailTextLabel?.text = suggestion.displayName
        cell.detailTextLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        cell.detailTextLabel?.textColor = UIColor.white.withAlphaComponent(0.8)

        // Little search icon on the left
        cell.imageView?.image = UIImage(systemName: "magnifyingglass")
        cell.imageView?.tintColor = UIColor.white.withAlphaComponent(0.9)

        cell.backgroundColor = .clear
        cell.selectionStyle = .default

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let suggestion = suggestions[indexPath.row]
        print("✅ selected:", suggestion.displayName)

        // Pass back to CityListViewController
        onCitySelected?(suggestion.name)

        // Go back to list
        navigationController?.popViewController(animated: true)
    }
}
