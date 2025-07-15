import UIKit

protocol NewHabitViewControllerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String)
}

final class NewHabitViewController: UIViewController {
    
    weak var delegate: NewHabitViewControllerDelegate?
    
    // MARK: - Private Properties for State
    
    private var schedule: Set<DayOfWeek> = []
    private var selectedCategoryTitle: String?
    private var selectedEmojiIndexPath: IndexPath?
    private var selectedColorIndexPath: IndexPath?
    
    // MARK: - UI Elements
    
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
    
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название трекера"
        textField.backgroundColor = UIColor(red: 0.9, green: 0.91, blue: 0.92, alpha: 0.3)
        textField.layer.cornerRadius = 16
        textField.translatesAutoresizingMaskIntoConstraints = false
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return textField
    }()
    
    private lazy var buttonsTableView: UITableView = {
        let tableView = UITableView()
        tableView.layer.cornerRadius = 16
        tableView.separatorStyle = .singleLine
        tableView.isScrollEnabled = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    private let emojis = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝️", "😪"
    ]
    
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
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.identifier)
        return collectionView
    }()
    
    private let colors: [UIColor] = [
        UIColor(red: 0.99, green: 0.30, blue: 0.29, alpha: 1.0), UIColor(red: 1.00, green: 0.53, blue: 0.12, alpha: 1.0),
        UIColor(red: 0.00, green: 0.48, blue: 0.98, alpha: 1.0), UIColor(red: 0.43, green: 0.27, blue: 0.99, alpha: 1.0),
        UIColor(red: 0.20, green: 0.81, blue: 0.41, alpha: 1.0), UIColor(red: 0.90, green: 0.43, blue: 0.83, alpha: 1.0),
        UIColor(red: 0.98, green: 0.82, blue: 0.82, alpha: 1.0), UIColor(red: 0.97, green: 0.86, blue: 0.51, alpha: 1.0),
        UIColor(red: 0.51, green: 0.68, blue: 0.97, alpha: 1.0), UIColor(red: 0.68, green: 0.51, blue: 0.97, alpha: 1.0),
        UIColor(red: 0.28, green: 0.85, blue: 0.99, alpha: 1.0), UIColor(red: 0.47, green: 0.83, blue: 0.42, alpha: 1.0),
        UIColor(red: 0.55, green: 0.45, blue: 0.88, alpha: 1.0), UIColor(red: 0.52, green: 0.50, blue: 0.91, alpha: 1.0),
        UIColor(red: 0.99, green: 0.57, blue: 0.73, alpha: 1.0), UIColor(red: 1.00, green: 0.68, blue: 0.68, alpha: 1.0),
        UIColor(red: 0.99, green: 0.82, blue: 0.35, alpha: 1.0), UIColor(red: 0.67, green: 0.82, blue: 0.47, alpha: 1.0)
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
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.identifier)
        return collectionView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.red, for: .normal)
        button.layer.borderColor = UIColor.red.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Новая привычка"
        view.backgroundColor = .white
        
        setupLayout()
        updateCreateButtonState()
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty,
              let category = selectedCategoryTitle,
              let selectedEmojiIndexPath = selectedEmojiIndexPath,
              let selectedColorIndexPath = selectedColorIndexPath
        else { return }
        
        let color = colors[selectedColorIndexPath.row]
        let emoji = emojis[selectedEmojiIndexPath.row]
        
        let newTracker = Tracker(
            id: UUID(),
            name: name,
            color: color,
            emoji: emoji,
            schedule: self.schedule
        )
        
        delegate?.didCreateTracker(newTracker, categoryTitle: category)
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidChange() {
        updateCreateButtonState()
    }
    
    // MARK: - Private Methods
    
    private func updateCreateButtonState() {
        let isNameEntered = !(nameTextField.text?.isEmpty ?? true)
        let isCategorySelected = selectedCategoryTitle != nil
        let isScheduleSet = !schedule.isEmpty
        let isEmojiSelected = selectedEmojiIndexPath != nil
        let isColorSelected = selectedColorIndexPath != nil
        
        if isNameEntered && isCategorySelected && isScheduleSet && isEmojiSelected && isColorSelected {
            createButton.isEnabled = true
            createButton.backgroundColor = .black
        } else {
            createButton.isEnabled = false
            createButton.backgroundColor = .gray
        }
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [nameTextField, buttonsTableView, emojiHeaderLabel, emojiCollectionView,
         colorHeaderLabel, colorCollectionView, cancelButton, createButton].forEach {
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
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
            emojiCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emojiCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emojiCollectionView.heightAnchor.constraint(equalToConstant: 204),
            
            colorHeaderLabel.topAnchor.constraint(equalTo: emojiCollectionView.bottomAnchor, constant: 16),
            colorHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            
            colorCollectionView.topAnchor.constraint(equalTo: colorHeaderLabel.bottomAnchor, constant: 24),
            colorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorCollectionView.heightAnchor.constraint(equalToConstant: 204),
            
            cancelButton.topAnchor.constraint(equalTo: colorCollectionView.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.trailingAnchor.constraint(equalTo: createButton.leadingAnchor, constant: -8),
            
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension NewHabitViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "buttonCell")
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = UIColor(red: 0.9, green: 0.91, blue: 0.92, alpha: 0.3)
        cell.selectionStyle = .none
        
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        cell.detailTextLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        cell.detailTextLabel?.textColor = .gray
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Категория"
            cell.detailTextLabel?.text = selectedCategoryTitle
        } else {
            cell.textLabel?.text = "Расписание"
            if !schedule.isEmpty {
                if schedule.count == DayOfWeek.allCases.count {
                    cell.detailTextLabel?.text = "Каждый день"
                } else {
                    let sortedSchedule = schedule.sorted { $0.calendarDayIndex() < $1.calendarDayIndex() }
                    cell.detailTextLabel?.text = sortedSchedule.map { $0.shortName }.joined(separator: ", ")
                }
            }
        }
        
        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            let categoryListVC = CategoryListViewController()
            categoryListVC.delegate = self
            navigationController?.pushViewController(categoryListVC, animated: true)
        } else {
            let scheduleVC = ScheduleViewController()
            scheduleVC.delegate = self
            navigationController?.pushViewController(scheduleVC, animated: true)
        }
    }
}

// MARK: - ScheduleViewControllerDelegate
extension NewHabitViewController: ScheduleViewControllerDelegate {
    func didConfirm(_ schedule: Set<DayOfWeek>) {
        self.schedule = schedule
        buttonsTableView.reloadData()
        updateCreateButtonState()
    }
}

// MARK: - CategoryListViewControllerDelegate
extension NewHabitViewController: CategoryListViewControllerDelegate {
    func didSelectCategory(_ category: TrackerCategory) {
        self.selectedCategoryTitle = category.title
        buttonsTableView.reloadData()
        updateCreateButtonState()
    }
}

// MARK: - UITextFieldDelegate
extension NewHabitViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension NewHabitViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == emojiCollectionView ? emojis.count : colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojiCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCell.identifier, for: indexPath) as? EmojiCell else { return UICollectionViewCell() }
            cell.emojiLabel.text = emojis[indexPath.row]
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCell.identifier, for: indexPath) as? ColorCell else { return UICollectionViewCell() }
            cell.colorView.backgroundColor = colors[indexPath.row]
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let availableWidth = collectionView.frame.width - 32 // Учитываем отступы коллекции
        let cellsPerRow: CGFloat = 6
        let cellWidth: CGFloat = 52
        let totalCellWidth = cellsPerRow * cellWidth
        let totalSpacing = availableWidth - totalCellWidth
        return totalSpacing / (cellsPerRow - 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            if let previousIndexPath = selectedEmojiIndexPath, let previousCell = collectionView.cellForItem(at: previousIndexPath) {
                previousCell.backgroundColor = .clear
            }
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.cornerRadius = 16
            cell?.backgroundColor = .lightGray
            selectedEmojiIndexPath = indexPath
        } else {
            if let previousIndexPath = selectedColorIndexPath, let previousCell = collectionView.cellForItem(at: previousIndexPath) {
                previousCell.layer.borderWidth = 0
            }
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.cornerRadius = 8
            cell?.layer.borderWidth = 3
            cell?.layer.borderColor = colors[indexPath.row].withAlphaComponent(0.3).cgColor
            selectedColorIndexPath = indexPath
        }
        updateCreateButtonState()
    }
}
