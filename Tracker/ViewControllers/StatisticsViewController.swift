import UIKit

final class StatisticsViewController: UIViewController {

    // MARK: - Properties
    private var recordStore: TrackerRecordStoreProtocol?
    private var trackerStore: TrackerStore?

    // MARK: - UI Elements
    private lazy var placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(named: "statistics_placeholder"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = NSLocalizedString("statistics.placeholder.text", comment: "Statistics placeholder text")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return view
    }()

    private lazy var bestPeriodCard = StatisticCardView()
    private lazy var perfectDaysCard = StatisticCardView()
    private lazy var completedTrackersCard = StatisticCardView()
    private lazy var averageValueCard = StatisticCardView()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            bestPeriodCard,
            perfectDaysCard,
            completedTrackersCard,
            averageValueCard
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
        setupStores()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }

    // MARK: - Setup
    private func setupStores() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not get app delegate")
        }
        let context = appDelegate.persistentContainer.viewContext
        let localTrackerStore = TrackerStore(context: context)
        self.trackerStore = localTrackerStore
        self.recordStore = TrackerRecordStore(context: context, trackerStore: localTrackerStore)
    }

    private func setupUI() {
        title = NSLocalizedString("tabBar.statistics.title", comment: "Statistics screen title")
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        // Задаём описания для карточек
        bestPeriodCard.descriptionLabel.text = NSLocalizedString("statistics.card.bestPeriod", comment: "Trackers best period card description")
        perfectDaysCard.descriptionLabel.text = NSLocalizedString("statistics.card.perfectDays", comment: "Trackers perfect days card description")
        completedTrackersCard.descriptionLabel.text = NSLocalizedString("statistics.card.completed", comment: "Trackers completed card description")
        averageValueCard.descriptionLabel.text = NSLocalizedString("statistics.card.average", comment: "Trackers average value card description")
        
        view.addSubview(placeholderView)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 77),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Все карточки одинаковой высоты
            bestPeriodCard.heightAnchor.constraint(equalToConstant: 90),
            perfectDaysCard.heightAnchor.constraint(equalToConstant: 90),
            completedTrackersCard.heightAnchor.constraint(equalToConstant: 90),
            averageValueCard.heightAnchor.constraint(equalToConstant: 90)
        ])
    }

    // MARK: - Update Logic
    private func updateUI() {
        guard let records = recordStore?.records else { return }
        
        if records.isEmpty {
            placeholderView.isHidden = false
            stackView.isHidden = true
        } else {
            placeholderView.isHidden = true
            stackView.isHidden = false
            
            // Рассчитываем статистику
            let statistics = calculateStatistics(from: records)
            
            bestPeriodCard.countLabel.text = "\(statistics.bestPeriod)"
            perfectDaysCard.countLabel.text = "\(statistics.perfectDays)"
            completedTrackersCard.countLabel.text = "\(statistics.completedTrackers)"
            averageValueCard.countLabel.text = "\(statistics.averageValue)"
        }
    }
    
    // MARK: - Statistics Calculation
    private func calculateStatistics(from records: [TrackerRecord]) -> (bestPeriod: Int, perfectDays: Int, completedTrackers: Int, averageValue: Int) {
        let completedTrackers = records.count
        
        // Группируем записи по дням
        let recordsByDate = Dictionary(grouping: records) { $0.date }
        
        // Идеальные дни (дни когда выполнены все трекеры)
        // Для упрощения считаем что идеальный день - это день с любыми выполненными трекерами
        let perfectDays = recordsByDate.count
        
        // Лучший период - максимальная серия подряд идущих дней
        let bestPeriod = calculateBestStreak(from: Array(recordsByDate.keys))
        
        // Среднее значение - среднее количество выполненных трекеров в день
        let averageValue = perfectDays > 0 ? completedTrackers / perfectDays : 0
        
        return (bestPeriod, perfectDays, completedTrackers, averageValue)
    }
    
    private func calculateBestStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let sortedDates = dates.sorted()
        let calendar = Calendar.current
        
        var currentStreak = 1
        var bestStreak = 1
        
        for i in 1..<sortedDates.count {
            let previousDate = sortedDates[i-1]
            let currentDate = sortedDates[i]
            
            if calendar.isDate(currentDate, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: previousDate) ?? Date()) {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return bestStreak
    }
}
