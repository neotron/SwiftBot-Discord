//
// Created by David Hedbor on 2/13/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import SwiftDiscord
import Mapper

struct MeowModel: Mappable {
    let file: String?

    init(map: Mapper) throws {
        file = map.optionalFrom("file")
    }
}

class RandomAnimalsMessageHandler: MessageHandler, URLSessionTaskDelegate {
    fileprivate var pendingCorgieChannels = [Int: Message]()
    fileprivate var urlSession: Foundation.URLSession?

    override init() {
        super.init()
        urlSession = Foundation.URLSession(configuration: URLSessionConfiguration.default,
                delegate: self, delegateQueue: OperationQueue.current);

    }

    override var prefixes: [MessageCommand]? {
        return [("random", nil)]
    }

    override var commands: [MessageCommand]? {
        return [("random", "Show image of random animal. Supports cat, dog, corgi, and kitten. Space between *random* and *animal* is optional.")]
    }

    override func handlePrefix(_ prefix: String, command: String, args: [String], message: Message) -> Bool {
        switch (command) {
        case "randomcat":
            handleRandomCat(message)
        case "randomdog":
            message.replyToChannel("http://www.randomdoggiegenerator.com/randomdoggie.php/\(Date().timeIntervalSince1970).jpg")
        case "randomkitten":
            message.replyToChannel("http://www.randomkittengenerator.com/cats/rotator.php/\(Date().timeIntervalSince1970).jpg")
        case "randomcorgi":
            handleRandomCorgi(message)
        default:
            return false
        }
        return true
    }

    override func handleCommand(_ command: String, args: [String], message: Message) -> Bool {
        switch (args.count) {
        case 0:
            message.replyToChannel("I know of the following random images: cat, dog corgi and kitten.")
            return true
        case 1:
            return handlePrefix(command, command: "\(command)\(args[0].lowercased())", args: args, message: message)
        default:
            return false // Only handle empty random
        }
    }


    fileprivate func handleRandomCat(_ message: Message) {
        #if false
        Alamofire.request("http://random.cat/meow").responseObject {
            (response: DataResponse<MeowModel>) in
                     if let url = response.result.value?.file {
                         message.replyToChannel(url)
                     } else {
                         message.replyToChannel("Unfortunately, I failed to find any random cats for you today. :-(")
                         LOG_ERROR("Failed to get meow: \(response.result.error)")
                     }
                 }
        #endif
    }

    fileprivate func handleRandomCorgi(_ message: Message) {

        guard let url = URL(string: "http://cor.gi/random") else {
            LOG_ERROR("Failed to create corgi url.")
            return
        }

        if let task = self.urlSession?.dataTask(with: url) {
            self.pendingCorgieChannels[task.taskIdentifier] = message
            task.resume()
        }
    }

    @available(OSX 10.9, *) func urlSession(_ session: URLSession, task: URLSessionTask,
                                            willPerformHTTPRedirection response: HTTPURLResponse,
                                            newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
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
