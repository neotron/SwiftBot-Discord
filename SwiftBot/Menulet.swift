//
// Created by David Hedbor on 2/20/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import AppKit

class Menulet : NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    private let preferencesController = Preferences()
    @IBOutlet weak var menu: NSMenu!
    
    override init() {
        super.init()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        statusItem.enabled = true
        let image = NSImage(named: "menulet")
        statusItem.image = image
        statusItem.alternateImage = NSImage(named:"menulet-inverted")
        statusItem.menu = menu
        statusItem.highlightMode = true
        statusItem.title = "SwiftBot"
    }

    @IBAction func openPreferences(sender: AnyObject) {
        preferencesController.openPreferences(sender)
    }

}
