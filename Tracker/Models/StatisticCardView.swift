import UIKit

final class StatisticCardView: UIView {

    // Лейбл для большого числа (e.g., "6")
    let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Лейбл для описания (e.g., "Трекеров завершено")
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Обновляем фрейм градиента при изменении размера
        gradientLayer.frame = bounds
        
        // Создаем маску для градиентной рамки
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 16)
        let innerPath = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 15)
        path.append(innerPath.reversing())
        maskLayer.path = path.cgPath
        gradientLayer.mask = maskLayer
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        
        // Добавляем градиентный слой
        layer.addSublayer(gradientLayer)
        
        // Настраиваем градиент
        gradientLayer.colors = [
            UIColor(red: 253/255, green: 76/255, blue: 73/255, alpha: 1).cgColor,  // Красный
            UIColor(red: 70/255, green: 230/255, blue: 157/255, alpha: 1).cgColor, // Зеленый
            UIColor(red: 13/255, green: 110/255, blue: 253/255, alpha: 1).cgColor  // Синий
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }
    
    private func setupSubviews() {
        addSubview(countLabel)
        addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            // Отступы для контента внутри карточки
            countLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }
}
