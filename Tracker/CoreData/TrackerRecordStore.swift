import CoreData
import UIKit

typealias TrackerRecordStoreCompletion = (Error?) -> Void

protocol TrackerRecordStoreProtocol {
    var records: [TrackerRecord] { get }
    var delegate: TrackerRecordStoreDelegate? { get set }
    func addRecord(for trackerId: UUID, on date: Date, completion: TrackerRecordStoreCompletion)
    func deleteRecord(for trackerId: UUID, on date: Date, completion: TrackerRecordStoreCompletion)
}

protocol TrackerRecordStoreDelegate: AnyObject {
    func storeDidUpdate()
}

final class TrackerRecordStore: NSObject {
    private let context: NSManagedObjectContext
    private let trackerStore: TrackerStore
    weak var delegate: TrackerRecordStoreDelegate?
    
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData> = {
        let fetchRequest = NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerRecordCoreData.date, ascending: true)]
        
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
    
    init(context: NSManagedObjectContext, trackerStore: TrackerStore) {
        self.context = context
        self.trackerStore = trackerStore
        super.init()
    }
    
    private func record(from coreData: TrackerRecordCoreData) -> TrackerRecord? {
        guard let id = coreData.tracker?.id, let date = coreData.date else { return nil }
        return TrackerRecord(trackerId: id, date: date)
    }
}

// MARK: - TrackerRecordStoreProtocol

extension TrackerRecordStore: TrackerRecordStoreProtocol {
    var records: [TrackerRecord] {
        return fetchedResultsController.fetchedObjects?.compactMap { record(from: $0) } ?? []
    }
    
    func addRecord(for trackerId: UUID, on date: Date, completion: TrackerRecordStoreCompletion) {
        guard let trackerCoreData = trackerStore.fetchTracker(with: trackerId) else {
            completion(StoreError.trackerNotFound)
            return
        }
        
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)
        
        let record = TrackerRecordCoreData(context: context)
        record.date = dateOnly
        record.tracker = trackerCoreData
        record.trackerId = trackerCoreData.id
        
        do {
            try context.save()
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func deleteRecord(for trackerId: UUID, on date: Date, completion: TrackerRecordStoreCompletion) {
        let request = NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            "tracker.id", trackerId as CVarArg, // <-- Вот так
            #keyPath(TrackerRecordCoreData.date), date as CVarArg
        )
        
        do {
            if let recordToDelete = try context.fetch(request).first {
                context.delete(recordToDelete)
                try context.save()
            }
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    enum StoreError: Error {
        case trackerNotFound
    }
}

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.storeDidUpdate()
    }
}
