//
//  DeleteClippingIntent.swift
//  Clip
//

import AppIntents
import ClipKit
import CoreData

struct DeleteClippingIntent: AppIntent
{
    static var title: LocalizedStringResource = "Delete Clipping"
    static var description = IntentDescription("Deletes the most recently added item in your clippings list.")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult
    {
        try await DatabaseManager.shared.prepareAsync()

        let context = DatabaseManager.shared.persistentContainer.viewContext
        try await context.perform {
            let fetchRequest = PasteboardItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K == NO", #keyPath(PasteboardItem.isMarkedForDeletion))
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PasteboardItem.date, ascending: false)]
            fetchRequest.fetchLimit = 1

            guard let item = try context.fetch(fetchRequest).first else {
                throw ClippingIntentError.noClippings
            }

            // Soft-delete, matching the existing swipe-to-delete convention elsewhere in the app.
            item.isMarkedForDeletion = true
            try context.save()
        }

        DatabaseManager.shared.postDidChangePasteboardNotification()

        return .result()
    }
}
