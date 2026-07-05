//
//  ClipShortcuts.swift
//  Clip
//

import AppIntents

struct ClipShortcuts: AppShortcutsProvider
{
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: GetClippingIntent(),
                    phrases: ["Get a clipping in \(.applicationName)"],
                    shortTitle: "Get Clipping",
                    systemImageName: "doc.on.clipboard")

        AppShortcut(intent: AddClippingIntent(),
                    phrases: ["Add a clipping in \(.applicationName)"],
                    shortTitle: "Add Clipping",
                    systemImageName: "doc.on.clipboard.fill")

        AppShortcut(intent: DeleteClippingIntent(),
                    phrases: ["Delete my last clipping in \(.applicationName)"],
                    shortTitle: "Delete Clipping",
                    systemImageName: "clipboard")

        AppShortcut(intent: DeleteAllClippingsIntent(),
                    phrases: ["Delete all clippings in \(.applicationName)"],
                    shortTitle: "Delete All Clippings",
                    systemImageName: "trash")
    }
}
