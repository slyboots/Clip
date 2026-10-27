//
//  ClippingEntity.swift
//  Clip
//

import AppIntents
import ClipKit
import UniformTypeIdentifiers

struct ClippingEntity: AppEntity
{
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Clipping"
    static var defaultQuery = ClippingEntityQuery()

    var id: String

    @Property(title: "Text")
    var text: String?

    @Property(title: "URL")
    var url: URL?

    @Property(title: "Image")
    var image: IntentFile?

    @Property(title: "Date Added")
    var date: Date

    var displayRepresentation: DisplayRepresentation {
        if let text { return DisplayRepresentation(title: "\(text)") }
        if let url { return DisplayRepresentation(title: "\(url.absoluteString)") }
        if image != nil { return DisplayRepresentation(title: "Image") }
        return DisplayRepresentation(title: "Clipping")
    }

    init(item: PasteboardItem)
    {
        self.id = item.objectID.uriRepresentation().absoluteString
        self.date = item.date

        switch item.preferredRepresentation?.type
        {
        case .image:
            if let data = item.preferredRepresentation?.dataValue,
               let utType = UTType(item.preferredRepresentation?.uti ?? "")
            {
                self.image = IntentFile(data: data, filename: "Clipping", type: utType)
            }

        case .url:
            self.url = item.preferredRepresentation?.urlValue

        case .text, .attributedText:
            self.text = item.preferredRepresentation?.stringValue

        case nil:
            break
        }
    }
}

struct ClippingEntityQuery: EntityQuery
{
    func entities(for identifiers: [String]) async throws -> [ClippingEntity]
    {
        return []
    }
}
