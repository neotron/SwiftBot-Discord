//
//  AppDelegate.swift
//  SwiftBot
//
//  Created by David Hedbor on 2/20/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//
import Foundation
import AppKit
import DiscordAPI
import Fabric
import Crashlytics


private class CrashlyticsLogger : Logger {
    override init() {
        NSUserDefaults.standardUserDefaults().registerDefaults(["NSApplicationCrashOnExceptions": true])
        Fabric.with([Crashlytics.self])
        super.init()
    }

    override func log(message: String, args: CVaListPointer) {
        CLSNSLogv(message, args)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var main: SwiftBotMain?
    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        Logger.instance = CrashlyticsLogger();
        let args = NSProcessInfo.processInfo().arguments
        Config.instance.setDevelopment(args.contains("--development"));
        self.main = SwiftBotMain()
        main?.runWithDoneCallback({
            LOG_INFO("Exiting gracefully.");
            exit(0);
        })

    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

