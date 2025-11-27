//
//  ViewController.swift
//  SimpleWeatherapp
//
//  Weather detail screen
//

import UIKit

class ViewController: UIViewController {

    // MARK: - Outlets from storyboard

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    @IBOutlet weak var feelsLikeLabel: UILabel!
    @IBOutlet weak var minTempLabel: UILabel!
    @IBOutlet weak var maxTempLabel: UILabel!

    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var sunriseLabel: UILabel!
    @IBOutlet weak var sunsetLabel: UILabel!

    @IBOutlet weak var iconImageView: UIImageView!

    // ViewModel injected from CityList
    var viewModel: WeatherViewModel!

    // MARK: - Private UI

    private let backgroundGradient = CAGradientLayer()
    private let statsCard = UIView()

    // 👇 NEW: scroll view + refresh control (added programmatically)
    private let scrollView = UIScrollView()
    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // If user somehow lands here without a city, create empty VM
        if viewModel == nil {
            viewModel = WeatherViewModel(cityName: nil,
                                         cachedWeather: nil,
                                         lastUpdated: nil)
        }

        // We want a normal (small) nav bar on this screen
        navigationItem.largeTitleDisplayMode = .never

        setupGradientBackground()
        styleUI()
        setupLayout()
        clearUI()
        setupBindings()
        configureInitialCityHeader()

        // 👇 add pull-to-refresh in code (no storyboard changes)
        setupScrollView()
        setupPullToRefresh()

        // Show cached / first-time state
        viewModel.handleInitialState()

        // Top-right refresh button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshButtonTapped)
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds

        statsCard.layer.cornerRadius = 20
        statsCard.layer.masksToBounds = false
        statsCard.layer.shadowColor = UIColor.black.cgColor
        statsCard.layer.shadowOpacity = 0.18
        statsCard.layer.shadowOffset = CGSize(width: 0, height: 8)
        statsCard.layer.shadowRadius = 16

        // keep scrollView's contentSize big enough to allow a pull
        scrollView.contentSize = CGSize(width: view.bounds.width,
                                        height: view.bounds.height + 1)
    }

    // MARK: - ScrollView + Pull to refresh (pure code)

    /// Transparent scroll view over the screen only to get pull-to-refresh.
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        // Put scrollView on top of all content
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupPullToRefresh() {
        refreshControl.tintColor = .white
        refreshControl.attributedTitle = NSAttributedString(
            string: "Pull to refresh",
            attributes: [.foregroundColor: UIColor.white]
        )
        refreshControl.addTarget(self,
                                 action: #selector(handlePullToRefresh),
                                 for: .valueChanged)
        scrollView.refreshControl = refreshControl
    }

    @objc private func handlePullToRefresh() {
        // Refresh ONLY this city
        viewModel.refreshWeather(using: nil)
    }

    // MARK: - Bindings

    private func setupBindings() {
        viewModel.onLoadingStateChange = { [weak self] isLoading in
            guard let self = self else { return }
            if isLoading {
                self.temperatureLabel.text = "Loading…"
                self.conditionLabel.text   = "Updating latest weather…"
                self.timeLabel.text        = ""

                // If user pulled to refresh, spinner is already visible.
                // If user tapped button, we can start spinner manually if we want.
                if !self.refreshControl.isRefreshing {
                    self.refreshControl.beginRefreshing()
                }
            } else {
                self.refreshControl.endRefreshing()
            }
        }

        viewModel.onWeatherUpdated = { [weak self] weather, lastUpdated in
            self?.updateUI(with: weather, lastUpdated: lastUpdated)
        }

        viewModel.onShowMessage = { [weak self] title, message in
            self?.showAlert(title: title, message: message)
        }

        viewModel.onShowFirstTimeMessage = { [weak self] cityName in
            guard let self = self else { return }
            self.cityLabel.text        = cityName
            self.conditionLabel.text   = "You have to call the API first time"
            self.temperatureLabel.text = "—"
        }

        viewModel.onShowStatusText = { [weak self] text in
            self?.conditionLabel.text = text
        }
    }

    private func configureInitialCityHeader() {
        if let cityName = viewModel.cityName {
            navigationItem.title = cityName
            cityLabel.text = cityName
        }
    }

    // MARK: - Styling

    private func setupGradientBackground() {
        backgroundGradient.frame = view.bounds
        backgroundGradient.colors = [
            UIColor.systemBlue.cgColor,
            UIColor.systemTeal.cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint   = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }

    private func styleUI() {
        view.tintColor = .white
        navigationController?.navigationBar.tintColor = .white

        cityLabel.textColor        = .white
        temperatureLabel.textColor = .white
        conditionLabel.textColor   = .white
        timeLabel.textColor        = UIColor.white.withAlphaComponent(0.85)

        cityLabel.font = .systemFont(ofSize: 32, weight: .bold)
        cityLabel.adjustsFontSizeToFitWidth = true
        cityLabel.minimumScaleFactor = 0.7
        cityLabel.textAlignment = .center

        temperatureLabel.font = .systemFont(ofSize: 72, weight: .heavy)
        temperatureLabel.adjustsFontSizeToFitWidth = true
        temperatureLabel.minimumScaleFactor = 0.5
        temperatureLabel.textAlignment = .center

        conditionLabel.font = .systemFont(ofSize: 22, weight: .medium)
        conditionLabel.textAlignment = .center

        timeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        timeLabel.textAlignment = .center

        let secondaryLabels: [UILabel] = [
            feelsLikeLabel,
            minTempLabel,
            maxTempLabel,
            humidityLabel,
            windLabel,
            sunriseLabel,
            sunsetLabel
        ]
        secondaryLabels.forEach { label in
            label.textColor = UIColor.white.withAlphaComponent(0.95)
            label.font      = .systemFont(ofSize: 14, weight: .regular)
        }

        if #available(iOS 13.0, *) {
            iconImageView.preferredSymbolConfiguration =
                UIImage.SymbolConfiguration(pointSize: 34, weight: .medium)
        }
        iconImageView.tintColor   = .white
        iconImageView.contentMode = .scaleAspectFit
    }

    // MARK: - Layout (programmatic) with blur card

    private func setupLayout() {
        // 1. Add statsCard to the view
        view.addSubview(statsCard)
        statsCard.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statsCard.topAnchor.constraint(equalTo: conditionLabel.bottomAnchor, constant: 40),
            statsCard.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                                              constant: -30)
        ])

        // 2. Blur effect inside statsCard
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let blurView   = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true

        statsCard.addSubview(blurView)
        statsCard.sendSubviewToBack(blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: statsCard.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor)
        ])

        // 3. Move bottom labels inside statsCard
        let bottomLabels: [UILabel] = [
            feelsLikeLabel,
            minTempLabel,
            maxTempLabel,
            humidityLabel,
            windLabel,
            sunriseLabel,
            sunsetLabel
        ]

        for label in bottomLabels {
            label.removeFromSuperview()
            statsCard.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            // Row 1: feels like | min | max
            feelsLikeLabel.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 18),
            feelsLikeLabel.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 18),

            minTempLabel.centerXAnchor.constraint(equalTo: statsCard.centerXAnchor),
            minTempLabel.topAnchor.constraint(equalTo: feelsLikeLabel.topAnchor),

            maxTempLabel.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -18),
            maxTempLabel.topAnchor.constraint(equalTo: feelsLikeLabel.topAnchor),

            // Row 2: humidity | wind
            humidityLabel.topAnchor.constraint(equalTo: feelsLikeLabel.bottomAnchor, constant: 14),
            humidityLabel.leadingAnchor.constraint(equalTo: feelsLikeLabel.leadingAnchor),

            windLabel.centerYAnchor.constraint(equalTo: humidityLabel.centerYAnchor),
            windLabel.trailingAnchor.constraint(equalTo: maxTempLabel.trailingAnchor),

            // Row 3: sunrise | sunset
            sunriseLabel.topAnchor.constraint(equalTo: humidityLabel.bottomAnchor, constant: 14),
            sunriseLabel.leadingAnchor.constraint(equalTo: feelsLikeLabel.leadingAnchor),

            sunsetLabel.centerYAnchor.constraint(equalTo: sunriseLabel.centerYAnchor),
            sunsetLabel.trailingAnchor.constraint(equalTo: maxTempLabel.trailingAnchor),
            sunsetLabel.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -18)
        ])
    }

    // MARK: - Actions

    @objc private func refreshButtonTapped() {
        // small haptic so tapping feels nice
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // refresh ONLY this city
        viewModel.refreshWeather(using: nil)
    }

    // MARK: - Helper: SF Symbol for condition

    private func symbolName(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain":
            return "cloud.rain.fill"
        case "drizzle":
            return "cloud.drizzle.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "snow":
            return "snow"
        case "mist", "fog", "haze", "smoke":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }

    // MARK: - Gradient depending on day / night

    private func applyGradient(for weather: WeatherResponse, at date: Date) {
        let timestamp = date.timeIntervalSince1970
        let sunrise   = TimeInterval(weather.sys.sunrise)
        let sunset    = TimeInterval(weather.sys.sunset)

        let isDay = timestamp >= sunrise && timestamp <= sunset

        if isDay {
            backgroundGradient.colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemTeal.cgColor
            ]
        } else {
            backgroundGradient.colors = [
                UIColor(red: 14/255, green: 17/255, blue: 40/255, alpha: 1).cgColor,
                UIColor(red: 36/255, green: 46/255, blue: 89/255, alpha: 1).cgColor
            ]
        }
    }

    // MARK: - Relative time helper

    private func relativeTimeString(since date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        let minute = 60
        let hour   = 60 * minute

        if seconds < minute {
            return "just now"
        } else if seconds < hour {
            let mins = seconds / minute
            return "\(mins) min ago"
        } else {
            let hrs = seconds / hour
            return "\(hrs) hr ago"
        }
    }

    // MARK: - UI updates

    private func updateUI(with weather: WeatherResponse, lastUpdated: Date?) {
        let dateToUse = lastUpdated ?? Date()
        applyGradient(for: weather, at: dateToUse)

        // City + country
        cityLabel.text = "\(weather.name), \(weather.sys.country)"
        navigationItem.title = weather.name

        // Temperature
        let temp    = Int(weather.main.temp.rounded())
        let feels   = Int(weather.main.feelsLike.rounded())
        let minTemp = Int(weather.main.tempMin.rounded())
        let maxTemp = Int(weather.main.tempMax.rounded())

        UIView.transition(with: temperatureLabel,
                          duration: 0.25,
                          options: .transitionCrossDissolve,
                          animations: {
            self.temperatureLabel.text = "\(temp)°"
        })

        // Condition & icon
        if let info = weather.weather.first {
            UIView.transition(with: conditionLabel,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: {
                self.conditionLabel.text = info.description.capitalized
            })

            let symbol = symbolName(for: info.main)
            UIView.transition(with: iconImageView,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: {
                self.iconImageView.image = UIImage(systemName: symbol)
            })
        } else {
            conditionLabel.text = "—"
            iconImageView.image = UIImage(systemName: "questionmark.circle")
        }

        // Last updated (relative)
        timeLabel.text = "Updated " + relativeTimeString(since: dateToUse)

        // Feels / min / max
        feelsLikeLabel.text = "Feels like \(feels)°"
        minTempLabel.text   = "Min \(minTemp)°"
        maxTempLabel.text   = "Max \(maxTemp)°"

        // Humidity / wind
        humidityLabel.text = "Humidity: \(weather.main.humidity)%"
        windLabel.text     = String(format: "Wind: %.1f m/s", weather.wind.speed)

        // Sunrise / sunset
        let sunFormatter = DateFormatter()
        sunFormatter.timeStyle = .short
        sunFormatter.dateStyle = .none
        sunFormatter.timeZone  = TimeZone(secondsFromGMT: weather.timezone)

        let sunriseDate = Date(timeIntervalSince1970: TimeInterval(weather.sys.sunrise))
        let sunsetDate  = Date(timeIntervalSince1970: TimeInterval(weather.sys.sunset))

        sunriseLabel.text = "Sunrise: \(sunFormatter.string(from: sunriseDate))"
        sunsetLabel.text  = "Sunset:  \(sunFormatter.string(from: sunsetDate))"
    }

    private func clearUI() {
        cityLabel.text        = "—"
        temperatureLabel.text = "—"
        conditionLabel.text   = ""
        timeLabel.text        = ""

        feelsLikeLabel.text = ""
        minTempLabel.text   = ""
        maxTempLabel.text   = ""
        humidityLabel.text  = ""
        windLabel.text      = ""
        sunriseLabel.text   = ""
        sunsetLabel.text    = ""
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
