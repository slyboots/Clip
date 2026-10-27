//
//  SettingsViewController.swift
//  Clip
//
//  Created by Riley Testut on 6/14/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit
import SwiftUI

import ClipKit

extension SettingsViewController
{
    static let settingsDidChangeNotification: Notification.Name = Notification.Name("SettingsDidChangeNotification")
}

class SettingsViewController: UIHostingController<SettingsView>
{
    @MainActor
    required dynamic init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder, rootView: SettingsView())

        self.title = NSLocalizedString("Settings", comment: "")
    }
}
