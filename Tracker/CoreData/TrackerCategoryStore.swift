import CoreData
import UIKit

protocol TrackerCategoryStoreDelegate: AnyObject {
    func storeDidUpdate()
}

final class TrackerCategoryStore: NSObject {
    private let context: NSManagedObjectContext
    weak var delegate: TrackerCategoryStoreDelegate?
    
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData> = {
        let fetchRequest = NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        try? controller.performFetch()
        return controller
    }()
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    var categories: [TrackerCategory] {
        guard let objects = self.fetchedResultsController.fetchedObjects,
              let categories = try? objects.map({ try self.trackerCategory(from: $0) })
        else { return [] }
        return categories
    }
    
    func trackerCategory(from coreDataObject: TrackerCategoryCoreData) throws -> TrackerCategory {
        guard let title = coreDataObject.title else {
            throw StoreError.decodingError
        }
        
        let trackersSet = coreDataObject.trackers as? Set<TrackerCoreData> ?? []
        
        let trackers = try trackersSet.map { try self.tracker(from: $0) }
        
        return TrackerCategory(title: title, trackers: trackers)
    }
    
    enum StoreError: Error {
        case decodingError
    }
    
    func fetchCategory(with title: String) -> TrackerCategoryCoreData? {
        let request = NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
        request.predicate = NSPredicate(format: "title == %@", title)
        let result = try? context.fetch(request)
        return result?.first
    }
    
    func createCategory(with title: String) throws -> TrackerCategoryCoreData {
        let category = TrackerCategoryCoreData(context: context)
        category.title = title
        try context.save()
        return category
    }
    
    private func tracker(from coreDataObject: TrackerCoreData) throws -> Tracker {
        guard
            let id = coreDataObject.id,
            let name = coreDataObject.name,
            let emoji = coreDataObject.emoji,
            let color = coreDataObject.color as? UIColor,
            let schedule = coreDataObject.schedule as? Set<DayOfWeek>
        else {
            throw StoreError.decodingError
        }
        
        return Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: schedule
        )
    }
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.storeDidUpdate()
    }
}
