//
//  DatabaseManager+Intents.swift
//  Clip
//

import ClipKit
import CoreData

extension DatabaseManager
{
    func prepareAsync() async throws
    {
        try await withCheckedThrowingContinuation { continuation in
            self.prepare { result in continuation.resume(with: result) }
        }
    }

    func postDidChangePasteboardNotification()
    {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), .didChangePasteboard, nil, nil, true)
    }
}
