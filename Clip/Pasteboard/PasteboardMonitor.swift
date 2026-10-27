//
//  PasteboardMonitor.swift
//  Clip
//
//  Created by Riley Testut on 6/11/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit
import AVFoundation
import UserNotifications
import CoreLocation

import ClipKit
import Roxas

private let PasteboardMonitorDidChangePasteboard: @convention(c) (CFNotificationCenter?, UnsafeMutableRawPointer?, CFNotificationName?, UnsafeRawPointer?, CFDictionary?) -> Void =
{ (center, observer, name, object, userInfo) in
    ApplicationMonitor.shared.pasteboardMonitor.didChangePasteboard()
}

private let PasteboardMonitorIgnoreNextPasteboardChange: @convention(c) (CFNotificationCenter?, UnsafeMutableRawPointer?, CFNotificationName?, UnsafeRawPointer?, CFDictionary?) -> Void =
{ (center, observer, name, object, userInfo) in
    ApplicationMonitor.shared.pasteboardMonitor.ignoreNextPasteboardChange = true
}

class PasteboardMonitor
{
    private(set) var isStarted = false
    fileprivate var ignoreNextPasteboardChange = false
    
    private let feedbackGenerator = UINotificationFeedbackGenerator()
}

extension PasteboardMonitor
{
    func start(completionHandler: @escaping (Result<Void, Error>) -> Void)
    {
        guard !self.isStarted else { return }
        self.isStarted = true
                
        self.registerForNotifications()
        completionHandler(.success(()))
    }
}

private extension PasteboardMonitor
{
    func registerForNotifications()
    {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(center, nil, PasteboardMonitorDidChangePasteboard, CFNotificationName.didChangePasteboard.rawValue, nil, .deliverImmediately)
        CFNotificationCenterAddObserver(center, nil, PasteboardMonitorIgnoreNextPasteboardChange, CFNotificationName.ignoreNextPasteboardChange.rawValue, nil, .deliverImmediately)
        
        #if !targetEnvironment(simulator)
        let beginListeningSelector = ["Notifications", "Change", "Pasteboard", "To", "Listening", "begin"].reversed().joined()
        
        let className = ["Connection", "Server", "PB"].reversed().joined()
        
        let PBServerConnection = NSClassFromString(className) as AnyObject
        _ = PBServerConnection.perform(NSSelectorFromString(beginListeningSelector))
        #endif
        
        let changedNotification = ["changed", "pasteboard", "apple", "com"].reversed().joined(separator: ".")
        NotificationCenter.default.addObserver(self, selector: #selector(PasteboardMonitor.pasteboardDidUpdate), name: Notification.Name(changedNotification), object: nil)
    }
    
    @objc func pasteboardDidUpdate()
    {
        guard !self.ignoreNextPasteboardChange else {
            self.ignoreNextPasteboardChange = false
            return
        }

        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .background
            {
                // Don't present notifications for items copied from within Clip.
                guard !UIPasteboard.general.contains(pasteboardTypes: [UTI.clipping]) else { return }
            }

            let isDebugModeEnabled = UserDefaults.shared.isDebugModeEnabled

            // `contains(pasteboardTypes:)` inspects type identifiers only, so it doesn't read (or prompt for) the clipboard contents.
            let hasSupportedContent = UIPasteboard.general.contains(pasteboardTypes: PasteboardItemRepresentation.supportedTypeIdentifiers)

            // By default, only notify when there's something Clip can actually save.
            // Debug mode restores notifications for every copy, surfacing metadata for unsupported items.
            guard hasSupportedContent || isDebugModeEnabled else { return }

            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                if settings.soundSetting == .enabled
                {
                    UIDevice.current.vibrate()
                }
            }

            let content = UNMutableNotificationContent()
            content.categoryIdentifier = UNNotificationCategory.clipboardReaderIdentifier

            var userInfo: [AnyHashable: Any] = [UNNotification.hasSupportedContentUserInfoKey: hasSupportedContent]

            if hasSupportedContent
            {
                content.title = NSLocalizedString("Clipboard Changed", comment: "")
                content.body = NSLocalizedString("Swipe down to save to Clip.", comment: "")
            }
            else
            {
                // Debug mode only: describe the unsupported item instead of offering to save it.
                let metadata = self.unsupportedContentMetadata()
                content.title = NSLocalizedString("Unsupported Content", comment: "")
                content.body = metadata.description
                userInfo[UNNotification.detectedTypesUserInfoKey] = metadata.typeIdentifiers.joined(separator: ", ")
                userInfo[UNNotification.dataSizeUserInfoKey] = metadata.byteCount
            }

            if let location = ApplicationMonitor.shared.locationManager.location
            {
                userInfo[UNNotification.latitudeUserInfoKey] = location.coordinate.latitude
                userInfo[UNNotification.longitudeUserInfoKey] = location.coordinate.longitude
            }

            content.userInfo = userInfo

            let request = UNNotificationRequest(identifier: "ClipboardChanged", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print(error)
                }
            }
        }
    }

    // Gathers the detected type identifiers and total byte size for an item Clip can't save. Debug-mode only.
    func unsupportedContentMetadata() -> (typeIdentifiers: [String], byteCount: Int, description: String)
    {
        let typeIdentifiers = UIPasteboard.general.types

        // Reading the data does surface the clipboard contents, but this path only runs for the opt-in debug setting.
        let byteCount = typeIdentifiers.reduce(0) { (total, type) in
            total + (UIPasteboard.general.data(forPasteboardType: type)?.count ?? 0)
        }

        let formattedSize = ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
        let primaryType = typeIdentifiers.first ?? NSLocalizedString("unknown type", comment: "")
        let description = "\(primaryType) • \(formattedSize)"

        return (typeIdentifiers, byteCount, description)
    }
}

private extension PasteboardMonitor
{
    func didChangePasteboard()
    {
        DatabaseManager.shared.refresh()
        
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["ClipboardChanged"])
    }
}
