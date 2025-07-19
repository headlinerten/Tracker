import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackersViewControllerTests: XCTestCase {

    func testTrackersViewControllerLight() {
        // Создаём контроллер
        let vc = TrackersViewController()
        
        // Делаем снимок и сравниваем с эталоном для светлой темы
        assertSnapshot(
            matching: vc,
            as: .image(traits: .init(userInterfaceStyle: .light))
        )
    }
    
    func testTrackersViewControllerDark() {
        // Создаём контроллер
        let vc = TrackersViewController()
        
        // Делаем снимок и сравниваем с эталоном для тёмной темы
        assertSnapshot(
            matching: vc,
            as: .image(traits: .init(userInterfaceStyle: .dark))
        )
    }
}
