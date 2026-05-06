//
//  HLWebSocket.swift
//  XCToolkit
//
//  WebSocket 封装，基于 Starscream，支持自动重连
//
//  使用示例：
//  let socket = HLWebSocket(url: "ws://192.168.1.1/ws")
//  socket.delegate = self
//  socket.connect()
//  socket.send(text: "hello")
//  socket.disconnect() // 主动断开，不会触发重连

import Foundation
import Starscream

// MARK: - Delegate

public protocol HLWebSocketDelegate: AnyObject {
    func webSocketDidConnect(_ socket: HLWebSocket)
    func webSocketDidDisconnect(_ socket: HLWebSocket, error: Error?)
    func webSocket(_ socket: HLWebSocket, didReceiveText text: String)
    func webSocket(_ socket: HLWebSocket, didReceiveData data: Data)
}

/// 默认空实现，delegate 方法按需实现
public extension HLWebSocketDelegate {
    func webSocketDidConnect(_ socket: HLWebSocket) {}
    func webSocketDidDisconnect(_ socket: HLWebSocket, error: Error?) {}
    func webSocket(_ socket: HLWebSocket, didReceiveText text: String) {}
    func webSocket(_ socket: HLWebSocket, didReceiveData data: Data) {}
}

// MARK: - HLWebSocket

public final class HLWebSocket {

    // MARK: - Public

    public weak var delegate: HLWebSocketDelegate?

    /// 是否已连接
    public private(set) var isConnected: Bool = false

    /// 重连间隔（秒），默认 3 秒
    public var reconnectInterval: TimeInterval = 3

    /// 最大重连次数，0 表示无限重连，默认 0
    public var maxReconnectCount: Int = 0

    // MARK: - Private

    private var socket: WebSocket?
    private let url: String
    private let headers: [String: String]

    /// 用户主动断开标志，主动断开不触发重连
    private var isManualDisconnect: Bool = false

    private var reconnectCount: Int = 0
    private var reconnectTimer: DispatchSourceTimer?

    // MARK: - Init

    public init(url: String, headers: [String: String] = [:]) {
        self.url = url
        self.headers = headers
    }

    // MARK: - Public Methods

    /// 连接
    public func connect() {
        guard let url = URL(string: self.url) else { return }
        isManualDisconnect = false
        reconnectCount = 0

        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }

    /// 主动断开（不触发重连）
    public func disconnect() {
        isManualDisconnect = true
        cancelReconnectTimer()
        socket?.disconnect()
    }

    /// 发送文本
    public func send(text: String) {
        socket?.write(string: text)
    }

    /// 发送二进制数据
    public func send(data: Data) {
        socket?.write(data: data)
    }

    /// 发送 Ping
    public func ping() {
        socket?.write(ping: Data())
    }

    // MARK: - Private: Reconnect

    private func scheduleReconnect() {
        guard !isManualDisconnect else { return }
        guard maxReconnectCount == 0 || reconnectCount < maxReconnectCount else { return }

        cancelReconnectTimer()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + reconnectInterval)
        timer.setEventHandler { [weak self] in
            guard let self = self, !self.isManualDisconnect else { return }
            self.reconnectCount += 1
            self.connect()
        }
        timer.resume()
        reconnectTimer = timer
    }

    private func cancelReconnectTimer() {
        reconnectTimer?.cancel()
        reconnectTimer = nil
    }
}

// MARK: - WebSocketDelegate

extension HLWebSocket: WebSocketDelegate {

    public func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            isConnected = true
            reconnectCount = 0
            cancelReconnectTimer()
            delegate?.webSocketDidConnect(self)

        case .disconnected(_, _), .cancelled:
            isConnected = false
            delegate?.webSocketDidDisconnect(self, error: nil)
            scheduleReconnect()

        case .error(let error):
            isConnected = false
            delegate?.webSocketDidDisconnect(self, error: error)
            scheduleReconnect()

        case .text(let text):
            delegate?.webSocket(self, didReceiveText: text)

        case .binary(let data):
            delegate?.webSocket(self, didReceiveData: data)

        case .ping, .pong, .viabilityChanged, .reconnectSuggested:
            break
        case .peerClosed:
            isConnected = false
            reconnectCount = 0
            cancelReconnectTimer()
        }
    }
}
