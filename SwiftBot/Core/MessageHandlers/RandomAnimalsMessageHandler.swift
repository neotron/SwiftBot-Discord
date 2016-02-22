//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import DiscordAPI
import Alamofire
import AlamofireJsonToObjects
import EVReflection

class MeowModel: EVObject {
    var file: String?
}

class RandomAnimalsMessageHandler: MessageHandler, NSURLSessionTaskDelegate {
    private var pendingCorgieChannels = [Int: Message]()
    private var urlSession: NSURLSession?

    override init() {
        super.init()
        urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                delegate: self, delegateQueue: NSOperationQueue.currentQueue());

    }

    override var prefixes: [MessageCommand]? {
        return [("random", nil)]
    }

    override var commands: [MessageCommand]? {
        return [("random", "Show image of random animal. Supports cat, dog, corgi and kitten. Space between *random* and *animal* is optiona.")]
    }

    override func handlePrefix(prefix: String, command: String, args: [String], message: Message) -> Bool {
        switch (command) {
        case "randomcat":
            handleRandomCat(message)
        case "randomdog":
            message.replyToChannel("http://www.randomdoggiegenerator.com/randomdoggie.php/\(NSDate().timeIntervalSince1970).jpg")
        case "randomkitten":
            message.replyToChannel("http://www.randomkittengenerator.com/cats/rotator.php/\(NSDate().timeIntervalSince1970).jpg")
        case "randomcorgi":
            handleRandomCorgi(message)
        default:
            return false
        }
        return true
    }

    override func handleCommand(command: String, args: [String], message: Message) -> Bool {
        switch (args.count) {
        case 0:
            message.replyToChannel("I know of the following random images: cat, dog corgi and kitten.")
            return true
        case 1:
            return handlePrefix(command, command: "\(command)\(args[0].lowercaseString)", args: args, message: message)
        default:
            return false // Only handle empty random
        }
    }


    private func handleRandomCat(message: Message) {
        EVReflection.setBundleIdentifier(SwiftBotMain)
        Alamofire.request(.GET, "http://random.cat/meow").responseObject {
            (response: Result<MeowModel, NSError>) in
            if let meow = response.value, url = meow.file {
                message.replyToChannel(url)
            } else {
                message.replyToChannel("Unfortunately, I failed to find any random cats for you today. :-(")
                LOG_ERROR("Failed to get meow: \(response.error)")
            }
        }
    }

    private func handleRandomCorgi(message: Message) {

        guard let url = NSURL(string: "http://cor.gi/random") else {
            LOG_ERROR("Failed to create corgi url.")
            return
        }

        if let task = self.urlSession?.dataTaskWithURL(url) {
            self.pendingCorgieChannels[task.taskIdentifier] = message
            task.resume()
        }
    }

    @available(OSX 10.9, *) func URLSession(session: NSURLSession, task: NSURLSessionTask,
                                            willPerformHTTPRedirection response: NSHTTPURLResponse,
                                            newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        if let message = self.pendingCorgieChannels[task.taskIdentifier] {
            if (response.statusCode == 302) {
                if let doge = response.allHeaderFields["Location"] as? String {
                    message.replyToChannel(doge)
                    return
                }
            }
            self.pendingCorgieChannels[task.taskIdentifier] = nil
        }
        task.cancel()
        completionHandler(nil)
    }
}
