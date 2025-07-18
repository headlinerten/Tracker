import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        // --- БЛОК ГЛОБАЛЬНОЙ НАСТРОЙКИ UI ---
        // Настройка Navigation Bar для всего приложения
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance

        // Настройка Tab Bar для всего приложения (с разделительной полоской)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        tabBarAppearance.shadowColor = .systemGray2 // Цвет разделителя
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Проверяем, был ли пройден онбординг
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if hasCompletedOnboarding {
            // Если да, показываем главный экран
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
        } else {
            // Если нет, показываем онбординг
            window.rootViewController = OnboardingContainerViewController(
                transitionStyle: .scroll,
                navigationOrientation: .horizontal
            )
        }
        
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // ...
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // ...
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // ...
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // ...
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // ...
    }
}
