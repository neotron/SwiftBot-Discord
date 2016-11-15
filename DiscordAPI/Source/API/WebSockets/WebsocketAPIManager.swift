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
    func websocketMessageReceived(_ message: MessageModel, event: MessageEventType)
}

open class WebsocketAPIManager: NSObject, WebSocketDelegate {
    weak var delegate: WebsocketAPIManagerDelegate?

    fileprivate var socket: WebSocket?
    fileprivate var timer: Timer?
    fileprivate var sequence: Int?

    open func fetchEndpointAndConnect() {
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

    fileprivate func connectWebSocket()
    {
        guard let urlString = Registry.instance.websocketEndpoint, let url = URL(string: urlString) else {
            LOG_ERROR("Failed to create websocket endpoint URL")
            delegate?.websocketEndpointError()
            return
        }
        socket = WebSocket(url: url)
        socket!.delegate = self
        socket!.connect()
    }

    func handleMessage(_ text: String) {
        if let message = Mapper<WebsocketMessageModel>().map(JSONString: text), let type = message.type, let data = message.data {
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

    func processMessage(_ dict: [String:AnyObject], event: MessageEventType) {
        if let message = Mapper<MessageModel>().map(JSON: dict) {
            if let authorId = message.author?.id, let myId = Registry.instance.user?.id {
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

    func processReady(_ dict: [String:AnyObject]) {
        if let ready = Mapper<WebsocketReadyMessageModel>().map(JSON: dict) {
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

    func enableKeepAlive(_ interval: Double) {
        cancelKeepAlive()
        LOG_DEBUG("Starting heartbeat timer with an interval of \(interval).");
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendHeartbeat), userInfo: nil, repeats: true)
    }

    func sendHeartbeat() {
        guard let sequence = self.sequence else {
            LOG_ERROR("Missing sequence for heartbeat.")
            return
        }
        if let socket = self.socket, let heartbeat = Mapper().toJSONString(WebsocketHeartbeatModel(sequence: sequence)) {
            socket.write(string: heartbeat)
            LOG_DEBUG("Sent heartbeat \(heartbeat)");
        }
    }

    // Websocket API callbacks below.
    open func websocketDidConnect(socket: WebSocket) {
        LOG_INFO("Websocket connected")
        if let helloMessage = Mapper().toJSONString(WebsocketHelloMessageModel()) {
            socket.write(string: helloMessage);
        }
    }

    open func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        cancelKeepAlive()
        if let err = error {
            LOG_ERROR("Websocket disconnected with error: \(err) - attempting reconnect")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(5*NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                self.socket = nil
                self.connectWebSocket()
            }
        } else {
            LOG_INFO("Websocket disconnected")
        }
    }

    open func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        LOG_DEBUG("Websocket text message received.")
        handleMessage(text)
    }

    open func websocketDidReceiveData(socket: WebSocket, data: Data) {
        do {
            let inflatedData = try data.gunzipped()
            if let text = String(data: inflatedData, encoding: String.Encoding.utf8) {
                LOG_DEBUG("Websocket binary message received (\(data.count) -> \(inflatedData.count))")
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
