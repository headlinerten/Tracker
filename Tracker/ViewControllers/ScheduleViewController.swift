import UIKit

protocol ScheduleViewControllerDelegate: AnyObject {
    func didConfirm(_ schedule: Set<DayOfWeek>)
}

final class ScheduleViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("schedule.title", comment: "Schedule selection screen title")
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemBackground
        
        view.addSubview(daysTableView)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            daysTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            daysTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            daysTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            daysTableView.heightAnchor.constraint(equalToConstant: 7 * 75), // 7 ячеек по 75
            
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        daysTableView.dataSource = self
        daysTableView.delegate = self
    }
    
    weak var delegate: ScheduleViewControllerDelegate?
    private var selectedDays: Set<DayOfWeek> = []
    
    @objc private func doneButtonTapped() {
        delegate?.didConfirm(selectedDays)
        navigationController?.popViewController(animated: true)
    }
    @objc
    private func switchChanged(_ sender: UISwitch) {
        let dayIndex = sender.tag
        let day = DayOfWeek.allCases[dayIndex]
        
        if sender.isOn {
            selectedDays.insert(day)
        } else {
            selectedDays.remove(day)
        }
    }
    
    private lazy var daysTableView: UITableView = {
        let tableView = UITableView()
        tableView.layer.cornerRadius = 16
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("schedule.doneButton.title", comment: "Done button on schedule screen"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
}

extension ScheduleViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let day = DayOfWeek.allCases[indexPath.row]
        cell.textLabel?.text = day.localizedName

        let switchView = UISwitch(frame: .zero)
        switchView.setOn(false, animated: false)
        switchView.tag = indexPath.row
        switchView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        
        cell.accessoryView = switchView
        cell.backgroundColor = .background
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}
