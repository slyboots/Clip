//
//  AddClippingIntent.swift
//  Clip
//

import AppIntents
import ClipKit
import UIKit
import UniformTypeIdentifiers

struct AddClippingIntent: AppIntent
{
    static var title: LocalizedStringResource = "Add Clipping"
    static var description = IntentDescription("Adds an item to your clippings list.")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Clipping")
    var content: IntentFile

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$content) to clippings")
    }

    func perform() async throws -> some IntentResult
    {
        try await DatabaseManager.shared.prepareAsync()

        let data = content.data
        let item: NSItemProviderWriting

        if content.type?.conforms(to: .image) == true, let uiImage = UIImage(data: data)
        {
            item = uiImage
        }
        else if let text = String(data: data, encoding: .utf8)
        {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

            if let url = URL(string: trimmed), url.scheme != nil
            {
                item = url as NSURL
            }
            else
            {
                item = trimmed as NSString
            }
        }
        else
        {
            throw ClippingIntentError.unsupportedContent
        }

        let context = DatabaseManager.shared.persistentContainer.viewContext
        try await context.perform {
            _ = PasteboardItem.make(item: item, context: context)
            try context.save()
        }

        DatabaseManager.shared.postDidChangePasteboardNotification()

        return .result()
    }
}
