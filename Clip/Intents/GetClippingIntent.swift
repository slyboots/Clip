//
//  GetClippingIntent.swift
//  Clip
//

import AppIntents
import ClipKit
import CoreData

struct GetClippingIntent: AppIntent
{
    static var title: LocalizedStringResource = "Get Clipping"
    static var description = IntentDescription("Returns the most recently added item in your clippings list.")

    // No UI needed for a pure data fetch, so avoid bringing the app to the foreground.
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<ClippingEntity>
    {
        try await DatabaseManager.shared.prepareAsync()

        let context = DatabaseManager.shared.persistentContainer.viewContext
        let item = try await context.perform {
            let fetchRequest = PasteboardItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K == NO", #keyPath(PasteboardItem.isMarkedForDeletion))
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PasteboardItem.date, ascending: false)]
            fetchRequest.fetchLimit = 1
            fetchRequest.relationshipKeyPathsForPrefetching = ["preferredRepresentation"]
            return try context.fetch(fetchRequest).first
        }

        guard let item else { throw ClippingIntentError.noClippings }

        return .result(value: ClippingEntity(item: item))
    }
}
