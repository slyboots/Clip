//
//  SettingsView.swift
//  Clip
//
//  Created by Riley Testut on 6/14/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import SwiftUI

import ClipKit

private extension HistoryLimit
{
    var localizedDescription: String {
        switch self
        {
        case .unlimited: return NSLocalizedString("Unlimited", comment: "")
        default: return String(format: NSLocalizedString("%d items", comment: ""), self.rawValue)
        }
    }
}

struct SettingsView: View
{
    @State private var historyLimit: HistoryLimit
    @State private var showLocationIcon: Bool
    @State private var isDebugModeEnabled: Bool

    init()
    {
        _historyLimit = State(initialValue: UserDefaults.shared.historyLimit)
        _showLocationIcon = State(initialValue: UserDefaults.shared.showLocationIcon)
        _isDebugModeEnabled = State(initialValue: UserDefaults.shared.isDebugModeEnabled)
    }

    var body: some View {
        Form {
            Section {
                Picker(NSLocalizedString("Keep Last…", comment: ""), selection: $historyLimit) {
                    ForEach(HistoryLimit.allCases, id: \.self) { limit in
                        Text(limit.localizedDescription).tag(limit)
                    }
                }
                .pickerStyle(.inline)
            }

            Section {
                Toggle(NSLocalizedString("Show Location Icons", comment: ""), isOn: $showLocationIcon)
            }

            Section {
                Toggle(NSLocalizedString("Debug Mode", comment: ""), isOn: $isDebugModeEnabled)
            } header: {
                Text(NSLocalizedString("Developer", comment: ""))
            } footer: {
                Text(NSLocalizedString("Show a notification for every copy. Items Clip can't save display their detected type and size instead of an option to save.", comment: ""))
            }
        }
        .onChange(of: historyLimit) { _, newValue in
            UserDefaults.shared.historyLimit = newValue
            Self.postSettingsDidChange()
        }
        .onChange(of: showLocationIcon) { _, newValue in
            UserDefaults.shared.showLocationIcon = newValue
            Self.postSettingsDidChange()
        }
        .onChange(of: isDebugModeEnabled) { _, newValue in
            UserDefaults.shared.isDebugModeEnabled = newValue
            Self.postSettingsDidChange()
        }
    }

    private static func postSettingsDidChange()
    {
        NotificationCenter.default.post(name: SettingsViewController.settingsDidChangeNotification, object: nil)
    }
}

#Preview {
    SettingsView()
}
