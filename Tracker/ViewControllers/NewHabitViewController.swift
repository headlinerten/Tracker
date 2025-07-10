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
        
        // Добавляем все элементы на view
        view.addSubview(nameTextField)
        view.addSubview(buttonsTableView)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
        
        // Активируем констрейнты
        NSLayoutConstraint.activate([
            // Поле ввода имени
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            // "Таблица" с кнопками
            buttonsTableView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            buttonsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonsTableView.heightAnchor.constraint(equalToConstant: 150), // 2 ячейки по 75
            
            // Кнопка Отменить
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            cancelButton.trailingAnchor.constraint(equalTo: createButton.leadingAnchor, constant: -8),
            
            // Кнопка Создать
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor)
        ])
        
        buttonsTableView.dataSource = self
        buttonsTableView.delegate = self
        
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        nameTextField.delegate = self
    }
    
    private var schedule: Set<DayOfWeek> = []
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createButtonTapped() {
        // 1. Собираем данные из полей
        guard let name = nameTextField.text, !name.isEmpty else {
            // Можно показать алерт, что имя не введено
            return
        }
        
        // Пока у нас нет UI для выбора цвета и эмодзи, используем значения по умолчанию
        let color = UIColor.systemBlue
        let emoji = "👍"
        
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
        // Проверяем, что текст в поле не пустой И что расписание не пустое
        if let text = nameTextField.text, !text.isEmpty, !schedule.isEmpty {
            // Если оба условия выполнены, делаем кнопку активной
            createButton.isEnabled = true
            createButton.backgroundColor = .black
        } else {
            // Если хотя бы одно условие не выполнено, делаем кнопку неактивной
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
