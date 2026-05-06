//
//  HLMQTTClient.swift
//  XCToolkit
//
//  MQTT 封装，基于 CocoaMQTT，支持自动重连
//
//  使用示例：
//  let mqtt = HLMQTTClient(host: "192.168.1.1", port: 1883)
//  mqtt.delegate = self
//  mqtt.connect(clientID: "device-001", username: "admin", password: "123456")
//  mqtt.subscribe(topic: "device/status")
//  mqtt.publish(topic: "device/cmd", message: "reboot")
//  mqtt.disconnect() // 主动断开，不触发重连

import Foundation
import CocoaMQTT

// MARK: - Delegate

public protocol HLMQTTDelegate: AnyObject {
    func mqttDidConnect(_ client: HLMQTTClient)
    func mqttDidDisconnect(_ client: HLMQTTClient, error: Error?)
    func mqtt(_ client: HLMQTTClient, didReceiveMessage message: String, topic: String)
    func mqtt(_ client: HLMQTTClient, didReceiveData data: Data, topic: String)
    func mqtt(_ client: HLMQTTClient, didSubscribe topic: String)
    func mqtt(_ client: HLMQTTClient, didPublish topic: String)
}

/// 默认空实现
public extension HLMQTTDelegate {
    func mqttDidConnect(_ client: HLMQTTClient) {}
    func mqttDidDisconnect(_ client: HLMQTTClient, error: Error?) {}
    func mqtt(_ client: HLMQTTClient, didReceiveMessage message: String, topic: String) {}
    func mqtt(_ client: HLMQTTClient, didReceiveData data: Data, topic: String) {}
    func mqtt(_ client: HLMQTTClient, didSubscribe topic: String) {}
    func mqtt(_ client: HLMQTTClient, didPublish topic: String) {}
}

// MARK: - HLMQTTClient

public final class HLMQTTClient {

    // MARK: - Public

    public weak var delegate: HLMQTTDelegate?

    /// 是否已连接
    public private(set) var isConnected: Bool = false

    /// 重连间隔（秒），默认 3 秒
    public var reconnectInterval: TimeInterval = 3

    /// 最大重连次数，0 表示无限重连，默认 0
    public var maxReconnectCount: Int = 0

    /// Keep Alive 间隔，默认 60 秒
    public var keepAlive: UInt16 = 60

    // MARK: - Private

    private let host: String
    private let port: UInt16

    private var mqtt: CocoaMQTT?
    private var clientID: String = ""
    private var username: String?
    private var password: String?

    /// 订阅列表（重连后自动恢复订阅）
    private var subscribedTopics: [String: CocoaMQTTQoS] = [:]

    private var isManualDisconnect: Bool = false
    private var reconnectCount: Int = 0
    private var reconnectTimer: DispatchSourceTimer?

    // MARK: - Init

    public init(host: String, port: UInt16 = 1883) {
        self.host = host
        self.port = port
    }

    // MARK: - Public Methods

    /// 连接
    public func connect(clientID: String, username: String? = nil, password: String? = nil) {
        self.clientID = clientID
        self.username = username
        self.password = password
        isManualDisconnect = false
        reconnectCount = 0
        setupAndConnect()
    }

    /// 主动断开（不触发重连）
    public func disconnect() {
        isManualDisconnect = true
        cancelReconnectTimer()
        mqtt?.disconnect()
    }

    /// 订阅主题
    public func subscribe(topic: String, qos: CocoaMQTTQoS = .qos1) {
        subscribedTopics[topic] = qos
        mqtt?.subscribe(topic, qos: qos)
    }

    /// 取消订阅
    public func unsubscribe(topic: String) {
        subscribedTopics.removeValue(forKey: topic)
        mqtt?.unsubscribe(topic)
    }

    /// 发布文本消息
    public func publish(topic: String, message: String, qos: CocoaMQTTQoS = .qos1, retained: Bool = false) {
        mqtt?.publish(topic, withString: message, qos: qos, retained: retained)
    }

    /// 发布二进制数据
    public func publish(topic: String, data: Data, qos: CocoaMQTTQoS = .qos1, retained: Bool = false) {
        let message = CocoaMQTTMessage(topic: topic, payload: [UInt8](data), qos: qos, retained: retained)
        mqtt?.publish(message)
    }

    // MARK: - Private

    private func setupAndConnect() {
        let client = CocoaMQTT(clientID: clientID, host: host, port: port)
        client.username = username
        client.password = password
        client.keepAlive = keepAlive
        client.delegate = self
        client.autoReconnect = false // 由我们自己管理重连
        mqtt = client
        _ = client.connect()
    }

    private func scheduleReconnect() {
        guard !isManualDisconnect else { return }
        guard maxReconnectCount == 0 || reconnectCount < maxReconnectCount else { return }

        cancelReconnectTimer()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + reconnectInterval)
        timer.setEventHandler { [weak self] in
            guard let self = self, !self.isManualDisconnect else { return }
            self.reconnectCount += 1
            self.setupAndConnect()
        }
        timer.resume()
        reconnectTimer = timer
    }

    private func cancelReconnectTimer() {
        reconnectTimer?.cancel()
        reconnectTimer = nil
    }

    /// 重连后恢复之前的订阅
    private func restoreSubscriptions() {
        subscribedTopics.forEach { topic, qos in
            mqtt?.subscribe(topic, qos: qos)
        }
    }
}

// MARK: - CocoaMQTTDelegate

extension HLMQTTClient: CocoaMQTTDelegate {

    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            isConnected = true
            reconnectCount = 0
            cancelReconnectTimer()
            restoreSubscriptions()
            delegate?.mqttDidConnect(self)
        } else {
            isConnected = false
            delegate?.mqttDidDisconnect(self, error: nil)
            scheduleReconnect()
        }
    }

    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        isConnected = false
        delegate?.mqttDidDisconnect(self, error: err)
        scheduleReconnect()
    }

    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        let topic = message.topic
        if let text = message.string {
            delegate?.mqtt(self, didReceiveMessage: text, topic: topic)
        }
        let data = Data(message.payload)
        delegate?.mqtt(self, didReceiveData: data, topic: topic)
    }

    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        success.allKeys.compactMap { $0 as? String }.forEach {
            delegate?.mqtt(self, didSubscribe: $0)
        }
    }

    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        delegate?.mqtt(self, didPublish: message.topic)
    }

    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {}
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {}
    public func mqttDidPing(_ mqtt: CocoaMQTT) {}
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}
}
