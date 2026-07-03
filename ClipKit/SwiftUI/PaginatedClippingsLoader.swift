//
//  PaginatedClippingsLoader.swift
//  ClipKit
//

import CoreData

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
        try? self.fetchedResultsController.performFetch()
        self.items = self.fetchedResultsController.fetchedObjects ?? []
    }

    public func loadMoreIfNeeded(currentItem: PasteboardItem)
    {
        guard let index = items.firstIndex(where: { $0.objectID == currentItem.objectID }), index >= items.count - 10 else { return }

        fetchedResultsController.fetchRequest.fetchLimit += pageSize
        try? fetchedResultsController.performFetch()
        self.items = fetchedResultsController.fetchedObjects ?? []
    }
}

extension PaginatedClippingsLoader: NSFetchedResultsControllerDelegate
{
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.items = self.fetchedResultsController.fetchedObjects ?? []
    }
}
