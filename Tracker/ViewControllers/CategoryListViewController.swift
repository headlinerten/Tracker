import UIKit

protocol CategoryListViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: TrackerCategory)
}

final class CategoryListViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CategoryListViewControllerDelegate?
    private var viewModel: CategoryViewModel!
    
    private var categories: [TrackerCategory] = []
    
    // MARK: - UI Elements
    
    private lazy var placeholderView: UIView = {
        let view = UIView()
        let imageView = UIImageView(image: UIImage(named: "star"))
        let label = UILabel()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.1
        paragraphStyle.alignment = .center
        
        let attributedString = NSAttributedString(
            string: NSLocalizedString("category.emptyState.text", comment: "Text for empty state on category screen"),
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
        )
        label.attributedText = attributedString
        label.numberOfLines = 2
        
        [imageView, label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "categoryCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 16
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.isScrollEnabled = false // Отключаем скролл
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true
        return tableView
    }()
    
    private lazy var addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("category.addCategoryButton.title", comment: "Add category button title"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(addCategoryButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        title = NSLocalizedString("category.title", comment: "Category selection screen title")
        view.backgroundColor = .systemBackground
        
        viewModel = CategoryViewModel()
        
        setupLayout()
        setupBindings()
        
        viewModel.loadCategories()
    }
    
    // MARK: - Private Methods
    
    private func setupLayout() {
        [tableView, placeholderView, addCategoryButton].forEach { view.addSubview($0) }
        
        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 75),
            
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupBindings() {
        viewModel.onCategoriesChange = { [weak self] categories in
            guard let self = self else { return }
            self.categories = categories
            let hasCategories = !categories.isEmpty
            self.placeholderView.isHidden = hasCategories
            self.tableView.isHidden = !hasCategories
            
            if hasCategories {
                self.updateTableViewHeight()
            }
            
            self.tableView.reloadData()
        }
        
        viewModel.onCategorySelect = { [weak self] selectedCategory in
            self?.delegate?.didSelectCategory(selectedCategory)
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    private func updateTableViewHeight() {
        let height = CGFloat(categories.count * 75)
        tableView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = height
            }
        }
    }
    
    @objc private func addCategoryButtonTapped() {
        let newCategoryVC = NewCategoryViewController()
        newCategoryVC.delegate = self
        let navController = UINavigationController(rootViewController: newCategoryVC)
        present(navController, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension CategoryListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let category = categories[indexPath.row]
        cell.textLabel?.text = category.title
        cell.backgroundColor = .background
        cell.selectionStyle = .none
        
        cell.layer.maskedCorners = []
        cell.layer.cornerRadius = 0
        
        if categories.count == 1 {
            cell.layer.cornerRadius = 16
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if indexPath.row == 0 {
            cell.layer.cornerRadius = 16
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if indexPath.row == categories.count - 1 {
            cell.layer.cornerRadius = 16
            cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        if indexPath.row == categories.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectCategory(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}

// MARK: - NewCategoryViewControllerDelegate
extension CategoryListViewController: NewCategoryViewControllerDelegate {
    func didCreateNewCategory(with title: String) {
        viewModel.createCategory(with: title)
    }
}
