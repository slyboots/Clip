//
//  DeleteAllClippingsIntent.swift
//  Clip
//

import AppIntents
import ClipKit
import CoreData

struct DeleteAllClippingsIntent: AppIntent
{
    static var title: LocalizedStringResource = "Delete All Clippings"
    static var description = IntentDescription("Deletes every item in your clippings list.")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult
    {
        try await DatabaseManager.shared.prepareAsync()

        let container = DatabaseManager.shared.persistentContainer

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.performBackgroundTask { context in
                do
                {
                    // No predicate: delete everything in a single batch delete, so no
                    // managed objects are ever faulted into memory.
                    let fetchRequest = PasteboardItem.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
                    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batchDeleteRequest.resultType = .resultTypeObjectIDs

                    let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                    let deletedObjectIDs = result?.result as? [NSManagedObjectID] ?? []

                    let changes = [NSDeletedObjectsKey: deletedObjectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])

                    continuation.resume()
                }
                catch
                {
                    continuation.resume(throwing: error)
                }
            }
        }

        DatabaseManager.shared.postDidChangePasteboardNotification()

        return .result()
    }
}
