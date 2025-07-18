import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - Filter
    private var currentFilter: FilterType = .allTrackers

    private lazy var filtersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("filters.button.title", comment: "Filters button title"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.backgroundColor = UIColor(named: "FilterButtonBlue")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(filtersButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        // Изначально кнопка скрыта
        button.isHidden = true
        return button
    }()
    
    // MARK: - Core Data Stores
    
    private var trackerStore: TrackerStore?
    private var categoryStore: TrackerCategoryStore?
    private var recordStore: TrackerRecordStoreProtocol?
    
    // MARK: - Properties
    
    private var visibleCategories: [TrackerCategory] = []
    private var completedRecords: Set<TrackerRecord> = []
    private var currentDate: Date = Date()
    private lazy var searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - UI Elements
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        picker.maximumDate = Date()
        
        picker.widthAnchor.constraint(equalToConstant: 120).isActive = true
                
        return picker
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()
    
    private lazy var placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(named: "star"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        let label = UILabel()
        label.text = NSLocalizedString("trackers.emptyState.text", comment: "Text for the empty state placeholder on the main screen")
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
        title = NSLocalizedString("trackers.title", comment: "Main screen title")
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        addButton.tintColor = .label
        addButton.accessibilityLabel = NSLocalizedString("trackers.plusButton.accessibilityLabel", comment: "Accessibility label for the 'Add Tracker' button")
        navigationItem.leftBarButtonItem = addButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
        
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("tabBar.trackers.title", comment: "Trackers tab bar item title"),
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: nil
        )
        
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        view.addSubview(placeholderView)
        view.addSubview(filtersButton)

        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
                filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                filtersButton.widthAnchor.constraint(equalToConstant: 114),
                filtersButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        
        searchController.searchResultsUpdater = self
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.placeholder = NSLocalizedString("trackers.searchField.placeholder", comment: "Placeholder for the search field")
            navigationItem.searchController = searchController
            definesPresentationContext = true
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
        let filterDate = calendar.startOfDay(for: currentDate)
        let filterWeekday = calendar.component(.weekday, from: filterDate)
        let searchText = (searchController.searchBar.text ?? "").lowercased()

        completedRecords = Set(recordStore?.records ?? [])

        // Шаг 1: Получаем все категории и фильтруем их по дате и тексту поиска
        let categoriesFilteredByDateAndSearch = categoryStore?.categories.compactMap { category -> TrackerCategory? in
            let trackers = category.trackers.filter { tracker in
                let scheduleContainsDay = tracker.schedule.contains { $0.calendarDayIndex() == filterWeekday }
                let nameMatchesSearch = searchText.isEmpty || tracker.name.lowercased().contains(searchText)
                return scheduleContainsDay && nameMatchesSearch
            }

            if trackers.isEmpty {
                return nil
            }
            return TrackerCategory(title: category.title, trackers: trackers)
        } ?? []
        
        // Шаг 2: Применяем фильтр "Завершённые" / "Незавершённые" к уже отфильтрованному списку
        switch currentFilter {
        case .completed:
            visibleCategories = categoriesFilteredByDateAndSearch.compactMap { category -> TrackerCategory? in
                let trackers = category.trackers.filter { isTrackerCompleted($0, on: filterDate) }
                if trackers.isEmpty { return nil }
                return TrackerCategory(title: category.title, trackers: trackers)
            }
        case .uncompleted:
            visibleCategories = categoriesFilteredByDateAndSearch.compactMap { category -> TrackerCategory? in
                let trackers = category.trackers.filter { !isTrackerCompleted($0, on: filterDate) }
                if trackers.isEmpty { return nil }
                return TrackerCategory(title: category.title, trackers: trackers)
            }
        case .allTrackers, .todayTrackers:
            visibleCategories = categoriesFilteredByDateAndSearch
        }
        
        // Шаг 3: Обновляем UI
        collectionView.reloadData()
        updatePlaceholders()
    }
    
    private func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        return completedRecords.contains { record in
            return record.trackerId == tracker.id && Calendar.current.isDate(record.date, inSameDayAs: date)
        }
    }

    private func updatePlaceholders() {
        if let categories = categoryStore?.categories, !categories.isEmpty {
            filtersButton.isHidden = false
        } else {
            filtersButton.isHidden = true
        }
        
        if visibleCategories.isEmpty {
            placeholderView.isHidden = false
            let isSearching = !(searchController.searchBar.text ?? "").isEmpty
            let placeholderLabel = placeholderView.subviews.first { $0 is UILabel } as? UILabel
            
            if isSearching {
                placeholderLabel?.text = "Ничего не найдено" // TODO: Локализовать
            } else {
                placeholderLabel?.text = NSLocalizedString("trackers.emptyState.text", comment: "Text for the empty state placeholder on the main screen")
            }
        } else {
            placeholderView.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.report(event: "open", screen: "Main")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AnalyticsService.report(event: "close", screen: "Main")
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        AnalyticsService.report(event: "click", screen: "Main", item: "add_track")
        let newHabitViewController = NewHabitViewController()
        newHabitViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: newHabitViewController)
        present(navigationController, animated: true)
    }
    
    @objc private func datePickerValueChanged() {
        currentDate = datePicker.date
        reloadVisibleCategories()
    }
    
    @objc private func filtersButtonTapped() {
        AnalyticsService.report(event: "click", screen: "Main", item: "filter")
        reportAnalytics(event: "click", item: "filter")
        let filtersVC = FiltersViewController()
        filtersVC.delegate = self
        filtersVC.currentFilter = self.currentFilter
        present(UINavigationController(rootViewController: filtersVC), animated: true)
    }
    
    private func reportAnalytics(event: String, item: String) {
        print("ANALYTICS: Event '\(event)' on item '\(item)' on screen 'Main'")
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
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] suggestedActions in
            guard let self = self else { return UIMenu() }

            // Создаём действие "Редактировать"
            let editAction = UIAction(
                title: NSLocalizedString("contextMenu.edit", comment: "Context menu edit action"),
            ) { action in
                AnalyticsService.report(event: "click", screen: "Main", item: "edit")
                self.reportAnalytics(event: "click", item: "edit")
                print("EDIT TAPPED FOR TRACKER: \(tracker.name)")
            }
            
            // Создаём действие "Удалить"
            let deleteAction = UIAction(
                title: NSLocalizedString("contextMenu.delete", comment: "Context menu delete action"),
                attributes: .destructive
            ) { action in
                AnalyticsService.report(event: "click", screen: "Main", item: "delete")
                self.reportAnalytics(event: "click", item: "delete")
                print("DELETE TAPPED FOR TRACKER: \(tracker.name)")
            }
            
            // Собираем и возвращаем меню
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
}

// MARK: - Delegate Implementations

extension TrackersViewController: TrackerCellDelegate {
    
    func completeTracker(id: UUID, at indexPath: IndexPath) {
        AnalyticsService.report(event: "click", screen: "Main", item: "track")
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

extension TrackersViewController: FiltersViewControllerDelegate {
    func didSelectFilter(_ filter: FilterType) {
        currentFilter = filter

        if filter == .todayTrackers {
            datePicker.date = Date()
            currentDate = Date()
        }

        reloadVisibleCategories()
    }
}

// MARK: - UISearchResultsUpdating

extension TrackersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        reloadVisibleCategories()
    }
}
