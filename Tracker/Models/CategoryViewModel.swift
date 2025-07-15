import Foundation
import UIKit

final class CategoryViewModel {
    private let categoryStore: TrackerCategoryStore
    
    var onCategoriesChange: (([TrackerCategory]) -> Void)?
    var onCategorySelect: ((TrackerCategory) -> Void)?
    
    init(categoryStore: TrackerCategoryStore = TrackerCategoryStore(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)) {
        self.categoryStore = categoryStore
        self.categoryStore.delegate = self
    }
    
    func loadCategories() {
        onCategoriesChange?(categoryStore.categories)
    }
    
    func didSelectCategory(at indexPath: IndexPath) {
        let selectedCategory = categoryStore.categories[indexPath.row]
        onCategorySelect?(selectedCategory)
    }
    
    func createCategory(with title: String) {
        try? categoryStore.createCategory(with: title)
    }
}

extension CategoryViewModel: TrackerCategoryStoreDelegate {
    func storeDidUpdate() {
        loadCategories()
    }
}
