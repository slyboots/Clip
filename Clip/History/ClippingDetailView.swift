//
//  ClippingDetailView.swift
//  Clip
//

import SwiftUI
import CoreFoundation

import ClipKit

struct ClippingDetailView: View
{
    @ObservedObject var pasteboardItem: PasteboardItem

    @State private var editedText: String = ""

    private var representation: PasteboardItemRepresentation? {
        self.pasteboardItem.preferredRepresentation
    }

    var body: some View {
        ScrollView {
            self.content
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(self.representation?.type.localizedName ?? NSLocalizedString("Unknown", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: self.copy) {
                    Label(NSLocalizedString("Copy", comment: ""), systemImage: "doc.on.doc")
                }
            }
        }
        .onAppear {
            guard self.representation?.type == .text else { return }
            self.editedText = self.representation?.stringValue ?? ""
        }
        .onDisappear(perform: self.saveTextIfNeeded)
    }

    @ViewBuilder
    private var content: some View {
        switch self.representation?.type
        {
        case .text:
            TextEditor(text: self.$editedText)
                .frame(minHeight: 200)

        case .attributedText:
            if let attributedString = self.representation?.attributedStringValue
            {
                Text(AttributedString(attributedString))
                    .textSelection(.enabled)
            }

        case .url:
            Text(self.representation?.urlValue?.absoluteString ?? "")
                .textSelection(.enabled)

        case .image:
            if let image = self.representation?.imageValue
            {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

        case nil:
            Text(NSLocalizedString("Unknown", comment: ""))
        }
    }
}

private extension ClippingDetailView
{
    func copy()
    {
        self.saveTextIfNeeded()

        // The main app monitors the pasteboard to show a "Clipboard Changed" notification;
        // ignore the change we're about to make ourselves.
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, .ignoreNextPasteboardChange, nil, nil, true)

        UIPasteboard.general.copy(self.pasteboardItem)
    }

    func saveTextIfNeeded()
    {
        guard let representation = self.representation, representation.type == .text, self.editedText != representation.stringValue else { return }
        representation.updateText(self.editedText)
    }
}
