import UIKit

class TrackersViewController: UIViewController {
    
    private var visibleCategories: [TrackerCategory] = []
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Создаем заголовок "Трекеры"
        title = "Трекеры"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Создаем кнопку "+"
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        addButton.tintColor = .black
        navigationItem.leftBarButtonItem = addButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
        
        // Настраиваем вид вкладки
        tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: nil
        )
        
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            // Прикрепляем верх коллекции к низу navigationBar
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            // Прикрепляем низ коллекции к верху tabBar
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Прикрепляем левый и правый края к краям view
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        
        view.addSubview(placeholderView)

        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        placeholderView.isHidden = true
        
        // Создаем несколько трекеров-привычек
        let tracker1 = Tracker(
            id: UUID(),
            name: "Поливать растения",
            color: .systemGreen,
            emoji: "🪴",
            schedule: [.wednesday, .friday]
        )

        let tracker2 = Tracker(
            id: UUID(),
            name: "Читать по 15 минут",
            color: .systemBlue,
            emoji: "📚",
            schedule: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )

        let tracker3 = Tracker(
            id: UUID(),
            name: "Сходить в зал",
            color: .systemOrange,
            emoji: "💪",
            schedule: [.tuesday, .thursday, .saturday]
        )

        // Создаем для них категории
        let homeCategory = TrackerCategory(
            title: "Домашние дела",
            trackers: [tracker1]
        )

        let selfCareCategory = TrackerCategory(
            title: "Забота о себе",
            trackers: [tracker2, tracker3]
        )

        // Заполняем наш массив-хранилище этими категориями
        self.categories = [homeCategory, selfCareCategory]
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(
            TrackerCategoryHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerCategoryHeader.identifier
        )
        
        datePickerValueChanged()
    }
    
    @objc private func addButtonTapped() {
        // 1. Создаем экземпляр нашего нового контроллера
        let newHabitViewController = NewHabitViewController()
        
        newHabitViewController.delegate = self

        // 2. Оборачиваем его в собственный UINavigationController
        let navigationController = UINavigationController(rootViewController: newHabitViewController)

        // 3. Показываем новый экран модально
        present(navigationController, animated: true)
    }
    
    @objc
    private func datePickerValueChanged() {
        let selectedDate = datePicker.date
        let calendar = Calendar.current
        // Получаем номер дня недели (1 - Вс, 2 - Пн, ..., 7 - Сб)
        let weekDay = calendar.component(.weekday, from: selectedDate)
        
        // Фильтруем наши категории
        visibleCategories = categories.compactMap { category in
            let trackers = category.trackers.filter { tracker in
                // Сравниваем день недели с расписанием трекера
                // Тут нужна будет небольшая функция для конвертации
                return tracker.schedule.contains(convertWeekday(weekDay))
            }
            
            if trackers.isEmpty {
                return nil
            }
            
            return TrackerCategory(
                title: category.title,
                trackers: trackers
            )
        }
        
        // Перезагружаем коллекцию, чтобы показать отфильтрованные данные
        collectionView.reloadData()
        placeholderView.isHidden = !visibleCategories.isEmpty
    }

    private func convertWeekday(_ weekday: Int) -> DayOfWeek {
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        return picker
    }()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()
    
    private lazy var collectionView: UICollectionView = {
        // Создаем "чертеж" (layout) для нашей коллекции
        let layout = UICollectionViewFlowLayout()
        
        // Создаем саму коллекцию с этим "чертежом"
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Устанавливаем цвет фона, чтобы он не отличался от фона вью
        collectionView.backgroundColor = .white
        
        return collectionView
    }()
    
    private lazy var placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем картинку
        let imageView = UIImageView(image: UIImage(named: "star"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Добавляем текст
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // Настраиваем констрейнты для картинки и текста внутри placeholderView
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return view
    }()
}

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
        
        // Назначаем контроллер делегатом ячейки
        cell.delegate = self
        
        // Проверяем, выполнен ли трекер сегодня
        let isCompleted = completedTrackers.contains { $0.trackerId == tracker.id && isSameDay($0.date, datePicker.date) }
        // Считаем, сколько раз всего был выполнен трекер
        let completedDays = completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        cell.configure(
            with: tracker,
            isCompleted: isCompleted,
            days: completedDays,
            indexPath: indexPath
        )
    
        return cell
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard
            kind == UICollectionView.elementKindSectionHeader,
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TrackerCategoryHeader.identifier,
                for: indexPath
            ) as? TrackerCategoryHeader
        else {
            return UICollectionReusableView()
        }

        view.titleLabel.text = visibleCategories[indexPath.section].title
        return view
    }
}

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Задаем количество ячеек в ряду
        let cellsPerRow: CGFloat = 2
        // Задаем отступы
        let leftInset: CGFloat = 16
        let rightInset: CGFloat = 16
        let cellSpacing: CGFloat = 9

        // Считаем доступную ширину
        let paddingWidth = leftInset + rightInset + (cellsPerRow - 1) * cellSpacing
        let availableWidth = collectionView.frame.width - paddingWidth

        // Считаем ширину ячейки
        let cellWidth = availableWidth / cellsPerRow

        return CGSize(width: cellWidth, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9 // Горизонтальный отступ
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16 // Вертикальный отступ
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
    }
}

extension TrackersViewController: TrackerCellDelegate {
    func completeTracker(id: UUID, at indexPath: IndexPath) {
        // 1. Проверяем, не выбрана ли дата в будущем
        let currentDate = Date()
        let selectedDate = datePicker.date
        
        // Сравниваем только компоненты даты, без времени
        if Calendar.current.compare(selectedDate, to: currentDate, toGranularity: .day) == .orderedDescending {
            print("Нельзя отмечать трекеры для будущих дат!")
            return // Выходим из функции, если дата в будущем
        }

        // 2. Ищем запись о выполнении в массиве completedTrackers
        if let index = completedTrackers.firstIndex(where: { $0.trackerId == id && isSameDay($0.date, selectedDate) }) {
            // 3. Если запись найдена — удаляем ее (снимаем отметку)
            completedTrackers.remove(at: index)
        } else {
            // 4. Если запись не найдена — создаем и добавляем ее (отмечаем выполнение)
            let newRecord = TrackerRecord(trackerId: id, date: selectedDate)
            completedTrackers.append(newRecord)
        }

        // 5. Обновляем только одну ячейку, на которую нажали
        collectionView.reloadItems(at: [indexPath])
    }
}

extension TrackersViewController: NewHabitViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        var updatedCategories = categories
        
        // Проверяем, существует ли уже категория с таким названием
        if let categoryIndex = updatedCategories.firstIndex(where: { $0.title == categoryTitle }) {
            // Если категория найдена, добавляем новый трекер в ее массив
            var updatedTrackers = updatedCategories[categoryIndex].trackers
            updatedTrackers.append(tracker)
            updatedCategories[categoryIndex] = TrackerCategory(title: categoryTitle, trackers: updatedTrackers)
        } else {
            // Если категория не найдена, создаем новую с этим трекером
            let newCategory = TrackerCategory(title: categoryTitle, trackers: [tracker])
            updatedCategories.append(newCategory)
        }
        
        // Обновляем наш основной массив категорий
        self.categories = updatedCategories
        
        // Вызываем фильтрацию по дате, чтобы на экране отобразился новый трекер,
        // если он соответствует текущему дню
        datePickerValueChanged()
    }
}
