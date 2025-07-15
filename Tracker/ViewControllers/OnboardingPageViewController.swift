import UIKit

final class OnboardingPageViewController: UIViewController {
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var textContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(text: String, backgroundImage: UIImage?) {
        super.init(nibName: nil, bundle: nil)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 38
        paragraphStyle.maximumLineHeight = 38
        paragraphStyle.alignment = .center
        
        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.black
            ]
        )
        
        textLabel.attributedText = attributedText
        backgroundImageView.image = backgroundImage
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }
    
    private func setupLayout() {
        view.addSubview(backgroundImageView)
        view.addSubview(textContainerView)
        textContainerView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            // Фон на весь экран
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            textContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textContainerView.heightAnchor.constraint(equalToConstant: 76),
            
            textLabel.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: textContainerView.trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: textContainerView.bottomAnchor)
        ])
    }
}
