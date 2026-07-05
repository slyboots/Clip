//
//  PaginatedClippingsLoader.swift
//  ClipKit
//

import CoreData
import CoreFoundation

private let PaginatedClippingsLoaderDidChangePasteboard: @convention(c) (CFNotificationCenter?, UnsafeMutableRawPointer?, CFNotificationName?, UnsafeRawPointer?, CFDictionary?) -> Void =
{ (center, observer, name, object, userInfo) in
    guard let observer = observer else { return }

    let loader = Unmanaged<PaginatedClippingsLoader>.fromOpaque(observer).takeUnretainedValue()
    DispatchQueue.main.async {
        loader.reload()
    }
}

public final class PaginatedClippingsLoader: NSObject, ObservableObject
{
    @Published public private(set) var items: [PasteboardItem] = []

    private let pageSize: Int
    private let fetchedResultsController: NSFetchedResultsController<PasteboardItem>

    public init(pageSize: Int = 100, context: NSManagedObjectContext = DatabaseManager.shared.persistentContainer.viewContext)
    {
        self.pageSize = pageSize

        let fetchRequest = PasteboardItem.historyFetchRequest(limit: pageSize)
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

        super.init()

        self.fetchedResultsController.delegate = self
        self.reload()

        // The database is written to by other processes (main app, notification extension),
        // which announce changes via this Darwin notification. NSFetchedResultsController
        // only sees in-process context changes, so re-fetch whenever it fires.
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(center, observer, PaginatedClippingsLoaderDidChangePasteboard, CFNotificationName.didChangePasteboard.rawValue, nil, .deliverImmediately)
    }

    deinit
    {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterRemoveObserver(center, observer, CFNotificationName.didChangePasteboard, nil)
    }

    public func reload()
    {
        try? self.fetchedResultsController.performFetch()
        self.items = self.fetchedResultsController.fetchedObjects ?? []
    }

    public func loadMoreIfNeeded(currentItem: PasteboardItem)
    {
        guard let index = items.firstIndex(where: { $0.objectID == currentItem.objectID }), index >= items.count - 10 else { return }

        fetchedResultsController.fetchRequest.fetchLimit += pageSize
        self.reload()
    }
}

extension PaginatedClippingsLoader: NSFetchedResultsControllerDelegate
{
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        // Re-fetch instead of reading fetchedObjects directly — change tracking is
        // unreliable when the fetch request has a fetchLimit.
        self.reload()
    }
}
