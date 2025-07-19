import UIKit

final class OnboardingContainerViewController: UIPageViewController {
    
    // Массив контроллеров-страниц
    private lazy var pages: [UIViewController] = {
        return [
            OnboardingPageViewController(
                text: NSLocalizedString("onboarding.firstPage.text", comment: "Text for the first onboarding screen"),
                backgroundImage: UIImage(named: "OnboardingBlue")
            ),
            OnboardingPageViewController(
                text: NSLocalizedString("onboarding.secondPage.text", comment: "Text for the second onboarding screen"),
                backgroundImage: UIImage(named: "OnboardingRed")
            )
        ]
    }()
    
    // Индикатор страниц (точки)
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.numberOfPages = pages.count
        control.currentPage = 0
        control.currentPageIndicatorTintColor = .black
        control.pageIndicatorTintColor = .black.withAlphaComponent(0.3)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    // Кнопка для перехода к основному приложению
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("onboarding.actionButton.title", comment: "Action button on onboarding screen"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        // Устанавливаем первую страницу
        if let firstPage = pages.first {
            setViewControllers([firstPage], direction: .forward, animated: true, completion: nil)
        }
        
        setupLayout()
    }
    
    private func setupLayout() {
        view.addSubview(actionButton)
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            actionButton.heightAnchor.constraint(equalToConstant: 60),
            
            pageControl.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -24),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func actionButtonTapped() {
        // Сохраняем флаг, что онбординг пройден
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Показываем главный экран приложения
        guard let window = UIApplication.shared.windows.first else { return }
        
        let trackersViewController = TrackersViewController()
        let navigationController = UINavigationController(rootViewController: trackersViewController)
        let statisticsViewController = StatisticsViewController()
        let statisticsNavigationController = UINavigationController(rootViewController: statisticsViewController)
        
        statisticsNavigationController.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tabBar.statistics.title", comment: "Statistics tab bar item title"),
            image: UIImage(systemName: "hare.fill"),
            selectedImage: nil
        )
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [navigationController, statisticsNavigationController]

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        
        // Плавная смена rootViewController
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}

// MARK: - UIPageViewControllerDataSource
extension OnboardingContainerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        guard nextIndex < pages.count else {
            return nil
        }
        
        return pages[nextIndex]
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
        }
    }
}
