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
        statusItem.menu = menu
        statusItem.image = NSImage(named: "MenuIcon")
        statusItem.image?.template = true
        statusItem.highlightMode = true
        statusItem.length = NSVariableStatusItemLength
        statusItem.enabled = true
        updateTitle()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTitle", name: Config.CONFIG_CHANGE_KEY, object: nil)
   }

    func updateTitle() {
        statusItem.title = Config.development ? "[Dev]   " : ""
    }

    @IBAction func openPreferences(sender: AnyObject) {
        preferencesController.openPreferences(sender)
    }

}
