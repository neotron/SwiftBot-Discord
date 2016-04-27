//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//
// Handles all communication over the Websocket API

import Foundation
import Starscream
import ObjectMapper
import Dispatch

public protocol WebsocketAPIManagerDelegate : class {
    func websocketAuthenticationError()
    func websocketEndpointError()
    func websocketMessageReceived(message: MessageModel, event: MessageEventType)
}

public class WebsocketAPIManager: NSObject, WebSocketDelegate {
    weak var delegate: WebsocketAPIManagerDelegate?

    private var socket: WebSocket?
    private var timer: NSTimer?
    private var sequence: Int?

    public func fetchEndpointAndConnect() {
        // This will fetch the websocket URL
        if Registry.instance.websocketEndpoint == nil {
            let request = GatewayUrlRequest()
            request.execute({
                (success: Bool) in
                if (success) {
                    self.connectWebSocket()
                } else {
                    LOG_ERROR("Websocket gateway request failed, no endpoint available.")
                    self.delegate?.websocketAuthenticationError()
                }
            });
        } else {
            connectWebSocket()
        }
    }

    private func connectWebSocket()
    {
        guard let urlString = Registry.instance.websocketEndpoint, url = NSURL(string: urlString) else {
            LOG_ERROR("Failed to create websocket endpoint URL")
            delegate?.websocketEndpointError()
            return
        }
        socket = WebSocket(url: url)
        socket!.delegate = self
        socket!.connect()
    }

    func handleMessage(text: String) {
        if let message = Mapper<WebsocketMessageModel>().map(text), type = message.type, data = message.data {
            self.sequence = message.sequence // for heart beat
            switch (type) {
            case "READY":
                processReady(data)

            case "MESSAGE_CREATE":
                processMessage(data, event: .Create)

            case "MESSAGE_UPDATE":
                processMessage(data, event: .Update)

            case "TYPING_START", "PRESENCE_UPDATE":
                // We don't care about these at all
                break

            default:
                LOG_INFO("Unhandled message received: \(type)")
            }
        }
    }

    func processMessage(dict: [String:AnyObject], event: MessageEventType) {
        if let message = Mapper<MessageModel>().map(dict) {
            if let authorId = message.author?.id, myId = Registry.instance.user?.id {
                if authorId == myId {
                    LOG_DEBUG("Ignoring message from myself.")
                    return
                }
            }
            LOG_DEBUG("Decoded \(event) message: \(message)")
            delegate?.websocketMessageReceived(message, event: event)
        } else {
            LOG_ERROR("Failed to decode message \(event) from dict \(dict)")
        }
    }

    func processReady(dict: [String:AnyObject]) {
        if let ready = Mapper<WebsocketReadyMessageModel>().map(dict) {
            if let hbi = ready.heartbeatInterval {
                LOG_INFO("Ready response received. Enabling heartbeat.")
                enableKeepAlive(Double(hbi) / 1000.0)
            } else {
                LOG_ERROR("Ready response received, heartbeat interval missing!.")
            }
            if let botuser = ready.user {
                Registry.instance.user = botuser // save user since we need user id later.
            }
        } else {
            LOG_ERROR("Ready response received but could not be parsed: \(dict)")
        }
    }


    func cancelKeepAlive() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }

    func enableKeepAlive(interval: Double) {
        cancelKeepAlive()
        LOG_DEBUG("Starting heartbeat timer with an interval of \(interval).");
        timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(sendHeartbeat), userInfo: nil, repeats: true)
    }

    func sendHeartbeat() {
        guard let sequence = self.sequence else {
            LOG_ERROR("Missing sequence for heartbeat.")
            return
        }
        if let socket = self.socket, heartbeat = Mapper().toJSONString(WebsocketHeartbeatModel(sequence: sequence)) {
            socket.writeString(heartbeat);
            LOG_DEBUG("Sent heartbeat \(heartbeat)");
        }
    }

    // Websocket API callbacks below.
    public func websocketDidConnect(socket: WebSocket) {
        LOG_INFO("Websocket connected")
        if let helloMessage = Mapper().toJSONString(WebsocketHelloMessageModel()) {
            socket.writeString(helloMessage);
        }
    }

    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        cancelKeepAlive()
        if let err = error {
            LOG_ERROR("Websocket disconnected with error: \(err) - attempting reconnect")
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(5*NSEC_PER_SEC)), dispatch_get_main_queue()) {
                self.socket = nil
                self.connectWebSocket()
            }
        } else {
            LOG_INFO("Websocket disconnected")
        }
    }

    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        LOG_DEBUG("Websocket text message received.")
        handleMessage(text)
    }

    public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        do {
            let inflatedData = try data.gunzippedData()
            if let text = String(data: inflatedData, encoding: NSUTF8StringEncoding) {
                LOG_DEBUG("Websocket binary message received (\(data.length) -> \(inflatedData.length))")
                handleMessage(text)
            } else {
                LOG_ERROR("Failed to decode binary message.")
            }
        } catch {
            LOG_ERROR("Failed to gunzip binary data packet.")
            return
        }
    }
}
