import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - Core Data Stores
    
    private var trackerStore: TrackerStore?
    private var categoryStore: TrackerCategoryStore?
    private var recordStore: TrackerRecordStoreProtocol?
    
    // MARK: - Properties
    
    private var visibleCategories: [TrackerCategory] = []
    private var completedRecords: Set<TrackerRecord> = []
    private var currentDate: Date = Date()
    
    // MARK: - UI Elements
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        // Нельзя выбрать будущую дату
        picker.maximumDate = Date()
        return picker
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        return collectionView
    }()
    
    private lazy var placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(named: "star"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupDelegates()
        setupStores()
        
        // Устанавливаем текущую дату и обновляем данные
        currentDate = datePicker.date
        reloadVisibleCategories()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        title = "Трекеры"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        addButton.tintColor = .black
        navigationItem.leftBarButtonItem = addButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
        
        tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: nil
        )
        
        view.backgroundColor = .white
        view.addSubview(collectionView)
        view.addSubview(placeholderView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupDelegates() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        collectionView.register(
            TrackerCategoryHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerCategoryHeader.identifier
        )
    }
    
    private func setupStores() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let localTrackerStore = TrackerStore(context: context)
        trackerStore = localTrackerStore
        
        categoryStore = TrackerCategoryStore(context: context)
        categoryStore?.delegate = self
        
        recordStore = TrackerRecordStore(context: context, trackerStore: localTrackerStore)
    }
    
    private func reloadVisibleCategories() {
        let calendar = Calendar.current
        // Убираем время из currentDate, чтобы сравнение было только по дате
        let filterDate = calendar.startOfDay(for: currentDate)
        let filterWeekday = calendar.component(.weekday, from: filterDate)
        
        // Обновляем список выполненных записей
        completedRecords = Set(recordStore?.records ?? [])
        
        visibleCategories = categoryStore?.categories.compactMap { category in
            let trackers = category.trackers.filter { tracker in
                // Проверяем, что трекер запланирован на выбранный день недели
                let scheduleContainsDay = tracker.schedule.contains { dayOfWeek in
                    // 1 = Вс, 2 = Пн, ..., 7 = Сб
                    // Наш enum: Пн = 0 ... Вс = 6
                    let calendarDayIndex = dayOfWeek.calendarDayIndex()
                    return calendarDayIndex == filterWeekday
                }
                return scheduleContainsDay
            }
            
            if trackers.isEmpty {
                return nil
            }
            
            return TrackerCategory(title: category.title, trackers: trackers)
        } ?? []
        
        collectionView.reloadData()
        placeholderView.isHidden = !visibleCategories.isEmpty
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        let newHabitViewController = NewHabitViewController()
        newHabitViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: newHabitViewController)
        present(navigationController, animated: true)
    }
    
    @objc private func datePickerValueChanged() {
        currentDate = datePicker.date
        reloadVisibleCategories()
    }
}

// MARK: - UICollectionViewDataSource

extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.identifier, for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        
        // Проверяем, выполнена ли задача на ТЕКУЩУЮ выбранную дату
        let isCompleted = completedRecords.contains { $0.trackerId == tracker.id && Calendar.current.isDate($0.date, inSameDayAs: currentDate) }
        
        // Считаем общее количество выполнений для этого трекера
        let daysCount = completedRecords.filter { $0.trackerId == tracker.id }.count
        
        cell.delegate = self
        cell.configure(with: tracker, isCompleted: isCompleted, days: daysCount, indexPath: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrackerCategoryHeader.identifier, for: indexPath) as? TrackerCategoryHeader else {
            return UICollectionReusableView()
        }
        
        view.titleLabel.text = visibleCategories[indexPath.section].title
        return view
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellsPerRow: CGFloat = 2
        let leftInset: CGFloat = 16
        let rightInset: CGFloat = 16
        let cellSpacing: CGFloat = 9
        
        let paddingWidth = leftInset + rightInset + (cellsPerRow - 1) * cellSpacing
        let availableWidth = collectionView.frame.width - paddingWidth
        let cellWidth = availableWidth / cellsPerRow
        
        return CGSize(width: cellWidth, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
    }
}

// MARK: - Delegate Implementations

extension TrackersViewController: TrackerCellDelegate {
    
    func completeTracker(id: UUID, at indexPath: IndexPath) {
        print("--- Кнопка нажата! ID трекера: \(id) ---")
        let calendar = Calendar.current
        
        if calendar.compare(currentDate, to: Date(), toGranularity: .day) == .orderedDescending {
            return
        }
        
        let dateOnly = calendar.startOfDay(for: currentDate)
        
        let record = TrackerRecord(trackerId: id, date: dateOnly)
        
        if completedRecords.contains(record) {
            // Если уже выполнен -> удаляем запись
            recordStore?.deleteRecord(for: id, on: dateOnly) { [weak self] error in
                guard let self = self else { return }
                if let error {
                    print("Ошибка удаления записи: \(error)")
                    return
                }
                self.completedRecords.remove(record)
                self.collectionView.reloadItems(at: [indexPath])
            }
        } else {
            recordStore?.addRecord(for: id, on: dateOnly) { [weak self] error in
                guard let self = self else { return }
                if let error {
                    print("Ошибка добавления записи: \(error)")
                    return
                }
                self.completedRecords.insert(record)
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
}

extension TrackersViewController: NewHabitViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        guard let categoryStore = self.categoryStore else { return }
        
        let category: TrackerCategoryCoreData
        if let existingCategory = categoryStore.fetchCategory(with: categoryTitle) {
            category = existingCategory
        } else {
            guard let newCategory = try? categoryStore.createCategory(with: categoryTitle) else {
                return
            }
            category = newCategory
        }
        
        try? trackerStore?.createTracker(tracker, in: category)
    }
}

extension TrackersViewController: TrackerCategoryStoreDelegate {
    func storeDidUpdate() {
        reloadVisibleCategories()
    }
}

extension DayOfWeek {
    func calendarDayIndex() -> Int {
        switch self {
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        case .sunday: return 1
        }
    }
}
