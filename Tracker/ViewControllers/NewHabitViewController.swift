import UIKit

protocol NewHabitViewControllerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String)
}

final class NewHabitViewController: UIViewController {
    
    weak var delegate: NewHabitViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Новая привычка"
        view.backgroundColor = .white
        
        // 1. Добавляем ScrollView на главный view
        view.addSubview(scrollView)
        
        // 2. В ScrollView добавляем contentView
        scrollView.addSubview(contentView)
        
        // 3. В contentView добавляем все остальные элементы
        contentView.addSubview(nameTextField)
        contentView.addSubview(buttonsTableView)
        contentView.addSubview(cancelButton)
        contentView.addSubview(createButton)
        contentView.addSubview(emojiHeaderLabel)
        contentView.addSubview(emojiCollectionView)
        contentView.addSubview(colorHeaderLabel)
        contentView.addSubview(colorCollectionView)
        
        // Назначаем делегатов для таблицы
        buttonsTableView.dataSource = self
        buttonsTableView.delegate = self
        
        // Назначаем таргет для текстового поля
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // 4. Активируем констрейнты
        NSLayoutConstraint.activate([
            // Констрейнты для scrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Констрейнты для contentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            // Ширина contentView должна быть равна ширине scrollView
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Констрейнты для UI-элементов, теперь относительно contentView
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            buttonsTableView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            buttonsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonsTableView.heightAnchor.constraint(equalToConstant: 150),
            
            emojiHeaderLabel.topAnchor.constraint(equalTo: buttonsTableView.bottomAnchor, constant: 32),
            emojiHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            emojiCollectionView.topAnchor.constraint(equalTo: emojiHeaderLabel.bottomAnchor, constant: 24),
            emojiCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            emojiCollectionView.heightAnchor.constraint(equalToConstant: 204),
            
            colorHeaderLabel.topAnchor.constraint(equalTo: emojiCollectionView.bottomAnchor, constant: 32),
            colorHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            colorCollectionView.topAnchor.constraint(equalTo: colorHeaderLabel.bottomAnchor, constant: 24),
            colorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            colorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            colorCollectionView.heightAnchor.constraint(equalToConstant: 204),
            
            // Привязываем кнопки к низу contentView, чтобы он знал свою высоту
            cancelButton.topAnchor.constraint(equalTo: colorCollectionView.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.trailingAnchor.constraint(equalTo: createButton.leadingAnchor, constant: -8),
            
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor)
        ])
        
        buttonsTableView.dataSource = self
        buttonsTableView.delegate = self
        
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        nameTextField.delegate = self
        
        emojiCollectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.identifier)
        emojiCollectionView.dataSource = self
        emojiCollectionView.delegate = self
        
        colorCollectionView.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.identifier)
        colorCollectionView.dataSource = self
        colorCollectionView.delegate = self
    }
    
    private var schedule: Set<DayOfWeek> = []
    private var selectedEmojiIndexPath: IndexPath?
    private var selectedColorIndexPath: IndexPath?
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty,
              let selectedEmojiIndexPath = selectedEmojiIndexPath,
              let selectedColorIndexPath = selectedColorIndexPath
        else { return }
        
        let color = colors[selectedColorIndexPath.row]
        let emoji = emojis[selectedEmojiIndexPath.row]
        
        // 2. Создаем наш новый трекер
        let newTracker = Tracker(
            id: UUID(),
            name: name,
            color: color,
            emoji: emoji,
            schedule: self.schedule // Используем расписание, полученное от экрана Schedule
        )
        
        // 3. Вызываем делегата и передаем ему данные
        // Категорию пока тоже используем по умолчанию
        delegate?.didCreateTracker(newTracker, categoryTitle: "Важное")
        
        // 4. Закрываем весь экран создания
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidChange() {
        updateCreateButtonState()
    }
    
    private func updateCreateButtonState() {
        // Проверяем, что все поля выбраны
        if let text = nameTextField.text, !text.isEmpty,
           !schedule.isEmpty,
           selectedEmojiIndexPath != nil,
           selectedColorIndexPath != nil {
            createButton.isEnabled = true
            createButton.backgroundColor = .black
        } else {
            createButton.isEnabled = false
            createButton.backgroundColor = .gray
        }
    }
    
    // Поле для ввода названия
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название трекера"
        textField.backgroundColor = UIColor(red: 0.9, green: 0.91, blue: 0.92, alpha: 0.3)
        textField.layer.cornerRadius = 16
        textField.translatesAutoresizingMaskIntoConstraints = false
        // Добавим отступ для текста слева
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    // "Таблица" для кнопок Категория и Расписание
    private lazy var buttonsTableView: UITableView = {
        let tableView = UITableView()
        tableView.layer.cornerRadius = 16
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // Кнопка Отменить
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor.red, for: .normal)
        button.layer.borderColor = UIColor.red.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Кнопка Создать
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .gray
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        return button
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojis = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝️", "😪"
    ]
    
    private let colors: [UIColor] = [
        UIColor(red: 0.99, green: 0.30, blue: 0.29, alpha: 1.0),
        UIColor(red: 1.00, green: 0.53, blue: 0.12, alpha: 1.0),
        UIColor(red: 0.00, green: 0.48, blue: 0.98, alpha: 1.0),
        UIColor(red: 0.43, green: 0.27, blue: 0.99, alpha: 1.0),
        UIColor(red: 0.20, green: 0.81, blue: 0.41, alpha: 1.0),
        UIColor(red: 0.90, green: 0.43, blue: 0.83, alpha: 1.0),
        UIColor(red: 0.98, green: 0.82, blue: 0.82, alpha: 1.0),
        UIColor(red: 0.97, green: 0.86, blue: 0.51, alpha: 1.0),
        UIColor(red: 0.51, green: 0.68, blue: 0.97, alpha: 1.0),
        UIColor(red: 0.68, green: 0.51, blue: 0.97, alpha: 1.0),
        UIColor(red: 0.28, green: 0.85, blue: 0.99, alpha: 1.0),
        UIColor(red: 0.47, green: 0.83, blue: 0.42, alpha: 1.0),
        UIColor(red: 0.55, green: 0.45, blue: 0.88, alpha: 1.0),
        UIColor(red: 0.52, green: 0.50, blue: 0.91, alpha: 1.0),
        UIColor(red: 0.99, green: 0.57, blue: 0.73, alpha: 1.0),
        UIColor(red: 1.00, green: 0.68, blue: 0.68, alpha: 1.0),
        UIColor(red: 0.99, green: 0.82, blue: 0.35, alpha: 1.0),
        UIColor(red: 0.67, green: 0.82, blue: 0.47, alpha: 1.0)
    ]
    
    private lazy var colorHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Цвет"
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var colorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    private lazy var emojiHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false // Отключаем скролл для вложенной коллекции
        return collectionView
    }()
}

extension NewHabitViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2 // У нас две "кнопки": Категория и Расписание
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = indexPath.row == 0 ? "Категория" : "Расписание"
        cell.accessoryType = .disclosureIndicator // Стрелочка справа
        cell.backgroundColor = UIColor(red: 0.9, green: 0.91, blue: 0.92, alpha: 0.3)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Снимаем выделение
        
        guard indexPath.row == 1 else { return }
        
        let scheduleViewController = ScheduleViewController()
        scheduleViewController.delegate = self
        navigationController?.pushViewController(scheduleViewController, animated: true)
    }
}

extension NewHabitViewController: ScheduleViewControllerDelegate {
    func didConfirm(_ schedule: Set<DayOfWeek>) {
        self.schedule = schedule
        updateCreateButtonState()
    }
}

extension NewHabitViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension NewHabitViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCollectionView {
            return emojis.count
        } else if collectionView == colorCollectionView {
            return colors.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojiCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCell.identifier, for: indexPath) as? EmojiCell else {
                return UICollectionViewCell()
            }
            cell.emojiLabel.text = emojis[indexPath.row]
            return cell
        } else if collectionView == colorCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCell.identifier, for: indexPath) as? ColorCell else {
                return UICollectionViewCell()
            }
            cell.colorView.backgroundColor = colors[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            if let previousIndexPath = selectedEmojiIndexPath {
                let previousCell = collectionView.cellForItem(at: previousIndexPath)
                previousCell?.backgroundColor = .clear
            }
            
            // Выделяем новую ячейку
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.cornerRadius = 16
            cell?.backgroundColor = .lightGray
            
            // Сохраняем indexPath новой выделенной ячейки
            selectedEmojiIndexPath = indexPath
            updateCreateButtonState()
            
        } else if collectionView == colorCollectionView {
            // Снимаем выделение со старой ячейки
            if let previousIndexPath = selectedColorIndexPath {
                let previousCell = collectionView.cellForItem(at: previousIndexPath)
                previousCell?.layer.borderWidth = 0
            }
            
            // Выделяем новую ячейку
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.cornerRadius = 8
            cell?.layer.borderWidth = 3
            cell?.layer.borderColor = colors[indexPath.row].withAlphaComponent(0.3).cgColor
            
            // Сохраняем indexPath новой выделенной ячейки
            selectedColorIndexPath = indexPath
            updateCreateButtonState()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.backgroundColor = .clear
        } else if collectionView == colorCollectionView {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 0
        }
    }
}
