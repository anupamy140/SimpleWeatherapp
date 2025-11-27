//
//  CityListViewController.swift
//  SimpleWeatherapp
//
//  Created by Anupam Yadav on 25/11/25.
//

import UIKit

// MARK: - Custom Cell

final class CityCell: UITableViewCell {
    static let reuseIdentifier = "CityCell"

    private let nameLabel = UILabel()
    private let tempLabel = UILabel()
    private let updatedLabel = UILabel()
    private let iconView = UIImageView()

    private let vStack = UIStackView()
    private let hStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        selectionStyle = .default
        accessoryType = .disclosureIndicator

        // Card-style background
        backgroundColor = .clear
        contentView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.9)
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        // Soft shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 12
        layer.masksToBounds = false

        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .label

        tempLabel.font = .systemFont(ofSize: 24, weight: .bold)
        tempLabel.textColor = .label
        tempLabel.setContentHuggingPriority(.required, for: .horizontal)

        updatedLabel.font = .systemFont(ofSize: 12, weight: .regular)
        updatedLabel.textColor = .secondaryLabel

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .label
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.alignment = .leading
        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(updatedLabel)

        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center

        // left → right: icon | text stack | temperature
        hStack.addArrangedSubview(iconView)
        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(tempLabel)

        contentView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(with city: City) {
        nameLabel.text = city.name

        guard let weather = city.lastWeather else {
            tempLabel.text = "--"
            tempLabel.textColor = .secondaryLabel
            updatedLabel.text = "Search first to load weather"
            iconView.image = UIImage(systemName: "questionmark.circle")
            return
        }

        let temp = Int(weather.main.temp.rounded())
        tempLabel.text = "\(temp)°C"

        // Temperature color by value
        switch temp {
        case ..<10:
            tempLabel.textColor = .systemTeal
        case 10..<25:
            tempLabel.textColor = .systemGreen
        case 25..<35:
            tempLabel.textColor = .systemOrange
        default:
            tempLabel.textColor = .systemRed
        }

        // Small condition icon
        let condition = weather.weather.first?.main.lowercased() ?? ""
        let symbolName: String
        switch condition {
        case "clear":         symbolName = "sun.max.fill"
        case "clouds":        symbolName = "cloud.fill"
        case "rain":          symbolName = "cloud.rain.fill"
        case "drizzle":       symbolName = "cloud.drizzle.fill"
        case "thunderstorm":  symbolName = "cloud.bolt.rain.fill"
        case "snow":          symbolName = "snow"
        case "mist", "fog",
             "haze", "smoke": symbolName = "cloud.fog.fill"
        default:              symbolName = "cloud.sun.fill"
        }
        iconView.image = UIImage(systemName: symbolName)

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        if let updated = city.lastUpdated {
            updatedLabel.text = "Updated \(formatter.string(from: updated))"
        } else {
            updatedLabel.text = "Last update time unknown"
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // spacing between cells
        let verticalInset: CGFloat = 6
        let horizontalInset: CGFloat = 12

        contentView.frame = contentView.frame.inset(
            by: UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        )
    }
}

// MARK: - City List VC

class CityListViewController: UITableViewController {

    private let viewModel = CityListViewModel()
    private let backgroundGradient = CAGradientLayer()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // fallback color behind gradient
        view.backgroundColor = .systemTeal

        setupNavigation()
        setupTableView()
        setupBackgroundGradient()
        setupRefreshControl()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // When coming back from detail, temperatures might have changed
        tableView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Make sure the background view fills the table view
        tableView.backgroundView?.frame = tableView.bounds

        // And make the gradient layer fill that background view
        backgroundGradient.frame = tableView.backgroundView?.bounds ?? tableView.bounds
    }

    // MARK: - Refresh control

    private func setupRefreshControl() {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshAllCities), for: .valueChanged)
        self.refreshControl = rc          // use UITableViewController’s property
    }

    @objc private func refreshAllCities() {
        viewModel.refreshAllCities { [weak self] in
            guard let self = self else { return }
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            self.generateHaptic(.light)   // subtle tap when refresh completes
        }
    }

    // MARK: - Background gradient

    private func setupBackgroundGradient() {
        let gradientView = UIView(frame: tableView.bounds)

        backgroundGradient.colors = [
            UIColor.systemBlue.cgColor,
            UIColor.systemTeal.cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint   = CGPoint(x: 1, y: 1)
        backgroundGradient.frame      = gradientView.bounds

        gradientView.layer.insertSublayer(backgroundGradient, at: 0)
        tableView.backgroundView = gradientView
    }

    // MARK: - Haptics

    private func generateHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = "Cities"

        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addCityTapped)
        )
        navigationItem.rightBarButtonItem = addButton

        // small nav bar everywhere
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBlue
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableView.register(CityCell.self, forCellReuseIdentifier: CityCell.reuseIdentifier)
    }

    // MARK: - Table data

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.numberOfRows

        // Empty-state message overlayed on the gradient background
        if let host = tableView.backgroundView {
            let tag = 999
            let label: UILabel

            if let existing = host.viewWithTag(tag) as? UILabel {
                label = existing
            } else {
                let lbl = UILabel()
                lbl.tag = tag
                lbl.textColor = UIColor.white.withAlphaComponent(0.9)
                lbl.numberOfLines = 0
                lbl.textAlignment = .center
                lbl.font = .systemFont(ofSize: 18, weight: .medium)
                lbl.translatesAutoresizingMaskIntoConstraints = false
                host.addSubview(lbl)

                NSLayoutConstraint.activate([
                    lbl.centerXAnchor.constraint(equalTo: host.centerXAnchor),
                    lbl.centerYAnchor.constraint(equalTo: host.centerYAnchor),
                    lbl.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor, constant: 24),
                    lbl.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor, constant: -24)
                ])

                label = lbl
            }

            if count == 0 {
                label.text = "No cities yet.\nTap + to add your first city."
                label.isHidden = false
            } else {
                label.isHidden = true
            }
        }

        return count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CityCell.reuseIdentifier,
            for: indexPath
        ) as? CityCell else {
            return UITableViewCell()
        }

        let city = viewModel.city(at: indexPath.row)
        cell.configure(with: city)
        cell.backgroundColor = .clear
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let city = viewModel.city(at: indexPath.row)

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(
            withIdentifier: "WeatherViewController"
        ) as? ViewController {

            vc.viewModel = WeatherViewModel(
                cityName: city.name,
                cachedWeather: city.lastWeather,
                lastUpdated: city.lastUpdated
            )

            navigationController?.pushViewController(vc, animated: true)
        }
    }

    // Swipe-to-delete
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteCity(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            generateHaptic(.light)      // tap when a city is removed
        }
    }

    // MARK: - Add city

    @objc private func addCityTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let addVC = storyboard.instantiateViewController(
            withIdentifier: "AddCitySearchViewController"
        ) as? AddCitySearchViewController else {
            print("❌ Could not load AddCitySearchViewController – check Storyboard ID & class")
            return
        }

        addVC.onCitySelected = { [weak self] cityName in
            guard let self = self else { return }

            self.viewModel.addCityAndFetchWeather(named: cityName) { [weak self] error in
                guard let self = self else { return }

                self.tableView.reloadData()
                self.generateHaptic(.medium)   // nice “thunk” when city is added

                if let error = error {
                    let alert = UIAlertController(
                        title: "Weather Error",
                        message: "City was added, but we couldn't load its weather.\n\(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }

        navigationController?.pushViewController(addVC, animated: true)
    }
}
