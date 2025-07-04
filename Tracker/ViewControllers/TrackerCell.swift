import UIKit

protocol TrackerCellDelegate: AnyObject {
    func completeTracker(id: UUID, at indexPath: IndexPath)
}

final class TrackerCell: UICollectionViewCell {
    
    weak var delegate: TrackerCellDelegate?
    
    private var isCompleted: Bool = false
    private var trackerId: UUID?
    private var indexPath: IndexPath?
    
    static let identifier = "trackerCell"
    
    // Цветная "плашка" для эмодзи и названия
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Лейбл для эмодзи
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Лейбл для названия трекера
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Лейбл для счетчика дней
    private let counterLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Кнопка "+" для отметки выполнения
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        // Устанавливаем иконку плюса
        let image = UIImage(systemName: "plus")
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 17 // половина от высоты/ширины 34
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(colorView)
        colorView.addSubview(emojiLabel)
        colorView.addSubview(nameLabel)
        contentView.addSubview(counterLabel)
        contentView.addSubview(plusButton)
        
        NSLayoutConstraint.activate([
            // colorView
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorView.heightAnchor.constraint(equalToConstant: 90),
            
            // emojiLabel (внутри colorView)
            emojiLabel.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            emojiLabel.topAnchor.constraint(equalTo: colorView.topAnchor, constant: 12),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),
            
            // nameLabel (внутри colorView)
            nameLabel.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: -12),
            nameLabel.bottomAnchor.constraint(equalTo: colorView.bottomAnchor, constant: -12),
            
            // plusButton (внутри contentView)
            plusButton.topAnchor.constraint(equalTo: colorView.bottomAnchor, constant: 8),
            plusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            plusButton.widthAnchor.constraint(equalToConstant: 34),
            plusButton.heightAnchor.constraint(equalToConstant: 34),
            
            // counterLabel (внутри contentView)
            counterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            counterLabel.centerYAnchor.constraint(equalTo: plusButton.centerYAnchor)
        ])
        
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with tracker: Tracker, isCompleted: Bool, days: Int, indexPath: IndexPath) {
        self.isCompleted = isCompleted
        self.trackerId = tracker.id
        self.indexPath = indexPath
        
        colorView.backgroundColor = tracker.color
        emojiLabel.text = tracker.emoji
        nameLabel.text = tracker.name
        
        let daysString: String
        // Склоняем слово "день" в зависимости от числа
        let lastDigit = days % 10
        let lastTwoDigits = days % 100
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            daysString = "\(days) дней"
        } else if lastDigit == 1 {
            daysString = "\(days) день"
        } else if lastDigit >= 2 && lastDigit <= 4 {
            daysString = "\(days) дня"
        } else {
            daysString = "\(days) дней"
        }
        counterLabel.text = daysString
        
        let image = isCompleted ? UIImage(systemName: "checkmark") : UIImage(systemName: "plus")
        plusButton.setImage(image, for: .normal)
        plusButton.backgroundColor = tracker.color
        plusButton.alpha = isCompleted ? 0.3 : 1.0
    }
    
    @objc
    private func plusButtonTapped() {
        guard let trackerId = trackerId, let indexPath = indexPath else { return }
        delegate?.completeTracker(id: trackerId, at: indexPath)
    }
}
