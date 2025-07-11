import CoreData
import UIKit

typealias TrackerRecordStoreCompletion = (Error?) -> Void

protocol TrackerRecordStoreProtocol {
    var records: [TrackerRecord] { get }
    func addRecord(for trackerId: UUID, on date: Date, completion: TrackerRecordStoreCompletion)
    func deleteRecord(for trackerId: UUID, on date: Date, completion: TrackerRecordStoreCompletion)
}

final class TrackerRecordStore: NSObject {
    private let context: NSManagedObjectContext
    private let trackerStore: TrackerStore
    
    // NSFetchedResultsController для автоматического отслеживания изменений
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData> = {
        let fetchRequest = NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerRecordCoreData.date, ascending: true)]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        try? controller.performFetch()
        return controller
    }()
    
    // Инициализатор теперь принимает и TrackerStore
    init(context: NSManagedObjectContext, trackerStore: TrackerStore) {
        self.context = context
        self.trackerStore = trackerStore
        super.init()
    }
    
    // Конвертируем объекты CoreData в наши структуры
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
        // Ищем запись по ID трекера и ТОЧНОЙ дате
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
