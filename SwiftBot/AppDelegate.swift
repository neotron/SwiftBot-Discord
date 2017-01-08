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



private class CrashlyticsLogger : Logger {
    override init() {
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        Fabric.with([Crashlytics.self])
        super.init()
    }

    override func log(_ message: String, args: CVaListPointer) {
        CLSNSLogv(message, args)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    fileprivate var main: SwiftBotMain?
    @IBOutlet weak var window: NSWindow!


    func launchWatchDog() {
        guard let watcherPath = Bundle.main.path(forResource: "SwiftBotKeeperAliver", ofType: nil, inDirectory: "../MacOS"),
        let selfPath = Bundle.main.path(forResource: "SwiftBot", ofType: nil, inDirectory: "../MacOS") else {
            LOG_ERROR("Can't find the watcher.")
            return
        }
        let task = Process()
        task.launchPath = watcherPath
        task.arguments = [selfPath, "\(getpid())"]
        task.launch()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        Logger.instance = CrashlyticsLogger();
        let args = ProcessInfo.processInfo.arguments
        Config.development = args.contains("--development")
#if false
        if !Config.development {
            launchWatchDog()
        }
#endif
        self.main = SwiftBotMain()
        main?.runWithDoneCallback({
            LOG_INFO("Exiting gracefully.")
            NSApp.terminate(self.main!)
        })

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

