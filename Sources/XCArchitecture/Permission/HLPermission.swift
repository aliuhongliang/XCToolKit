//
//  HLPermission.swift
//  XCToolkit
//
//  权限申请统一入口
//
//  使用示例：
//  // Closure
//  HLPermission.request(.camera) { status in ... }
//  HLPermission.status(.camera) { status in ... }
//
//  // async/await
//  let status = await HLPermission.request(.camera)
//  let status = await HLPermission.status(.camera)


//  使用前请在 Info.plist 中按需添加以下权限描述：
//
//  相机:          NSCameraUsageDescription
//  麦克风:        NSMicrophoneUsageDescription
//  相册:          NSPhotoLibraryUsageDescription
//  定位(使用期间): NSLocationWhenInUseUsageDescription
//  定位(始终):    NSLocationAlwaysAndWhenInUseUsageDescription
//  联系人:        NSContactsUsageDescription
//  日历:          NSCalendarsUsageDescription
//  提醒事项:      NSRemindersUsageDescription
//  蓝牙:          NSBluetoothAlwaysUsageDescription
//  运动健身:      NSMotionUsageDescription
//  面容ID:        NSFaceIDUsageDescription
//  语音识别:      NSSpeechRecognitionUsageDescription
//  Siri:          NSSiriUsageDescription
//  媒体资料库:    NSAppleMusicUsageDescription
//  追踪(IDFA):    NSUserTrackingUsageDescription

import AVFoundation
import Photos
import CoreLocation
import UserNotifications
import Contacts
import EventKit
import CoreBluetooth
import CoreMotion
import LocalAuthentication
import Speech
import Intents
import MediaPlayer
import AppTrackingTransparency

public final class HLPermission {

    // MARK: - Private

    private init() {}

    // 定位相关：需要持有 manager 和 delegate 防止被释放
    private static let locationManager = CLLocationManager()
    private static let locationDelegate = HLLocationDelegate()
    private static var locationCompletion: ((HLPermissionStatus) -> Void)?

    // 蓝牙：需要持有 manager
    private static var bluetoothManager: CBCentralManager?
    private static var bluetoothCompletion: ((HLPermissionStatus) -> Void)?
    private static let bluetoothDelegate = HLBluetoothDelegate()

    // MARK: - Public: Closure

    /// 查询权限状态（不会触发系统弹窗）
    public static func status(_ type: HLPermissionType, completion: @escaping (HLPermissionStatus) -> Void) {
        switch type {
        case .camera:
            completion(cameraStatus())
        case .microphone:
            completion(microphoneStatus())
        case .photoLibrary:
            completion(photoLibraryStatus())
        case .locationWhenInUse, .locationAlways:
            completion(locationStatus())
        case .notification:
            notificationStatus(completion: completion)
        case .contacts:
            completion(contactsStatus())
        case .calendar:
            completion(eventKitStatus(for: .event))
        case .reminder:
            completion(eventKitStatus(for: .reminder))
        case .bluetooth:
            completion(bluetoothStatus())
        case .motion:
            completion(motionStatus())
        case .faceID:
            completion(faceIDStatus())
        case .speechRecognition:
            completion(speechStatus())
        case .siri:
            completion(siriStatus())
        case .mediaLibrary:
            completion(mediaLibraryStatus())
        case .tracking:
            completion(trackingStatus())
        }
    }

    /// 请求权限（会触发系统弹窗，已授权/已拒绝时直接回调）
    public static func request(_ type: HLPermissionType, completion: @escaping (HLPermissionStatus) -> Void) {
        switch type {
        case .camera:
            requestCamera(completion: completion)
        case .microphone:
            requestMicrophone(completion: completion)
        case .photoLibrary:
            requestPhotoLibrary(completion: completion)
        case .locationWhenInUse:
            requestLocation(always: false, completion: completion)
        case .locationAlways:
            requestLocation(always: true, completion: completion)
        case .notification:
            requestNotification(completion: completion)
        case .contacts:
            requestContacts(completion: completion)
        case .calendar:
            requestEventKit(for: .event, completion: completion)
        case .reminder:
            requestEventKit(for: .reminder, completion: completion)
        case .bluetooth:
            requestBluetooth(completion: completion)
        case .motion:
            requestMotion(completion: completion)
        case .faceID:
            requestFaceID(completion: completion)
        case .speechRecognition:
            requestSpeech(completion: completion)
        case .siri:
            requestSiri(completion: completion)
        case .mediaLibrary:
            requestMediaLibrary(completion: completion)
        case .tracking:
            requestTracking(completion: completion)
        }
    }

    // MARK: - Public: async/await

    /// 查询权限状态（async）
    public static func status(_ type: HLPermissionType) async -> HLPermissionStatus {
        await withCheckedContinuation { continuation in
            status(type) { continuation.resume(returning: $0) }
        }
    }

    /// 请求权限（async）
    public static func request(_ type: HLPermissionType) async -> HLPermissionStatus {
        await withCheckedContinuation { continuation in
            request(type) { continuation.resume(returning: $0) }
        }
    }
}

// MARK: - Camera

private extension HLPermission {

    static func cameraStatus() -> HLPermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:       return .authorized
        case .denied:           return .denied
        case .restricted:       return .restricted
        case .notDetermined:    return .notDetermined
        @unknown default:       return .notDetermined
        }
    }

    static func requestCamera(completion: @escaping (HLPermissionStatus) -> Void) {
        let current = cameraStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { completion(granted ? .authorized : .denied) }
        }
    }
}

// MARK: - Microphone

private extension HLPermission {

    static func microphoneStatus() -> HLPermissionStatus {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:      return .authorized
        case .denied:       return .denied
        case .undetermined: return .notDetermined
        @unknown default:   return .notDetermined
        }
    }

    static func requestMicrophone(completion: @escaping (HLPermissionStatus) -> Void) {
        let current = microphoneStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async { completion(granted ? .authorized : .denied) }
        }
    }
}

// MARK: - Photo Library

private extension HLPermission {

    static func photoLibraryStatus() -> HLPermissionStatus {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }
        return mapPhotoStatus(status)
    }

    static func mapPhotoStatus(_ status: PHAuthorizationStatus) -> HLPermissionStatus {
        switch status {
        case .authorized:       return .authorized
        case .denied:           return .denied
        case .restricted:       return .restricted
        case .notDetermined:    return .notDetermined
        case .limited:          return .limited
        @unknown default:       return .notDetermined
        }
    }

    static func requestPhotoLibrary(completion: @escaping (HLPermissionStatus) -> Void) {
        let current = photoLibraryStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async { completion(mapPhotoStatus(status)) }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async { completion(mapPhotoStatus(status)) }
            }
        }
    }
}

// MARK: - Location

private extension HLPermission {

    static func locationStatus() -> HLPermissionStatus {
        let status: CLAuthorizationStatus
        if #available(iOS 14, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:   return .authorized
        case .denied:                                   return .denied
        case .restricted:                               return .restricted
        case .notDetermined:                            return .notDetermined
        @unknown default:                               return .notDetermined
        }
    }

    static func requestLocation(always: Bool, completion: @escaping (HLPermissionStatus) -> Void) {
        let current = locationStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        locationDelegate.completion = completion
        locationManager.delegate = locationDelegate
        if always {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

// MARK: - Notification

private extension HLPermission {

    static func notificationStatus(completion: @escaping (HLPermissionStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status: HLPermissionStatus
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:    status = .authorized
            case .denied:                                   status = .denied
            case .notDetermined:                            status = .notDetermined
            @unknown default:                               status = .notDetermined
            }
            DispatchQueue.main.async { completion(status) }
        }
    }

    static func requestNotification(completion: @escaping (HLPermissionStatus) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted ? .authorized : .denied) }
        }
    }
}

// MARK: - Contacts

private extension HLPermission {

    static func contactsStatus() -> HLPermissionStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:       return .authorized
        case .denied:           return .denied
        case .restricted:       return .restricted
        case .notDetermined:    return .notDetermined
        @unknown default:       return .notDetermined
        }
    }

    static func requestContacts(completion: @escaping (HLPermissionStatus) -> Void) {
        let current = contactsStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async { completion(granted ? .authorized : .denied) }
        }
    }
}

// MARK: - EventKit (Calendar / Reminder)

private extension HLPermission {

    static func eventKitStatus(for type: EKEntityType) -> HLPermissionStatus {
        switch EKEventStore.authorizationStatus(for: type) {
        case .authorized:       return .authorized
        case .denied:           return .denied
        case .restricted:       return .restricted
        case .notDetermined:    return .notDetermined
        @unknown default:       return .notDetermined
        }
    }

    static func requestEventKit(for type: EKEntityType, completion: @escaping (HLPermissionStatus) -> Void) {
        let current = eventKitStatus(for: type)
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        EKEventStore().requestAccess(to: type) { granted, _ in
            DispatchQueue.main.async { completion(granted ? .authorized : .denied) }
        }
    }
}

// MARK: - Bluetooth

/// 内部蓝牙代理
final class HLBluetoothDelegate: NSObject, CBCentralManagerDelegate {
    var completion: ((HLPermissionStatus) -> Void)?

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let completion = completion else { return }
        let status: HLPermissionStatus
        if #available(iOS 13.1, *) {
            switch central.authorization {
            case .allowedAlways:    status = .authorized
            case .denied:           status = .denied
            case .restricted:       status = .restricted
            case .notDetermined:    status = .notDetermined
            @unknown default:       status = .notDetermined
            }
        } else {
            status = central.state == .unauthorized ? .denied : .authorized
        }
        DispatchQueue.main.async {
            completion(status)
            self.completion = nil
        }
    }
}

private extension HLPermission {

    static func bluetoothStatus() -> HLPermissionStatus {
        if #available(iOS 13.1, *) {
            switch CBCentralManager.authorization {
            case .allowedAlways:    return .authorized
            case .denied:           return .denied
            case .restricted:       return .restricted
            case .notDetermined:    return .notDetermined
            @unknown default:       return .notDetermined
            }
        }
        return .notDetermined
    }

    static func requestBluetooth(completion: @escaping (HLPermissionStatus) -> Void) {
        let current = bluetoothStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        bluetoothDelegate.completion = completion
        bluetoothManager = CBCentralManager(delegate: bluetoothDelegate, queue: nil)
    }
}

// MARK: - Motion

private extension HLPermission {

    static func motionStatus() -> HLPermissionStatus {
        if #available(iOS 11, *) {
            switch CMMotionActivityManager.authorizationStatus() {
            case .authorized:       return .authorized
            case .denied:           return .denied
            case .restricted:       return .restricted
            case .notDetermined:    return .notDetermined
            @unknown default:       return .notDetermined
            }
        }
        return .notDetermined
    }

    static func requestMotion(completion: @escaping (HLPermissionStatus) -> Void) {
        let current = motionStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        // CMMotionActivityManager 通过实际查询触发弹窗
        let manager = CMMotionActivityManager()
        let now = Date()
        manager.queryActivityStarting(from: now, to: now, to: .main) { _, error in
            manager.stopActivityUpdates()
            if let error = error as NSError?, error.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                completion(.denied)
            } else {
                completion(.authorized)
            }
        }
    }
}

// MARK: - Face ID

private extension HLPermission {

    static func faceIDStatus() -> HLPermissionStatus {
        let context = LAContext()
        var error: NSError?
        let canEval = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if canEval { return .authorized }
        if let err = error {
            if err.code == LAError.biometryNotEnrolled.rawValue { return .notDetermined }
            if err.code == LAError.biometryNotAvailable.rawValue { return .denied }
        }
        return .notDetermined
    }

    static func requestFaceID(completion: @escaping (HLPermissionStatus) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async { completion(faceIDStatus()) }
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: " ") { success, _ in
            DispatchQueue.main.async { completion(success ? .authorized : .denied) }
        }
    }
}

// MARK: - Speech Recognition

private extension HLPermission {

    static func speechStatus() -> HLPermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:       return .authorized
        case .denied:           return .denied
        case .restricted:       return .restricted
        case .notDetermined:    return .notDetermined
        @unknown default:       return .notDetermined
        }
    }

    static func requestSpeech(completion: @escaping (HLPermissionStatus) -> Void) {
        let current = speechStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        SFSpeechRecognizer.requestAuthorization { status in
            let result: HLPermissionStatus
            switch status {
            case .authorized:       result = .authorized
            case .denied:           result = .denied
            case .restricted:       result = .restricted
            case .notDetermined:    result = .notDetermined
            @unknown default:       result = .notDetermined
            }
            DispatchQueue.main.async { completion(result) }
        }
    }
}

// MARK: - Siri

private extension HLPermission {

    static func siriStatus() -> HLPermissionStatus {
        switch INPreferences.siriAuthorizationStatus() {
        case .authorized:       return .authorized
        case .denied:           return .denied
        case .restricted:       return .restricted
        case .notDetermined:    return .notDetermined
        @unknown default:       return .notDetermined
        }
    }

    static func requestSiri(completion: @escaping (HLPermissionStatus) -> Void) {
        let current = siriStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        INPreferences.requestSiriAuthorization { status in
            let result: HLPermissionStatus
            switch status {
            case .authorized:       result = .authorized
            case .denied:           result = .denied
            case .restricted:       result = .restricted
            case .notDetermined:    result = .notDetermined
            @unknown default:       result = .notDetermined
            }
            DispatchQueue.main.async { completion(result) }
        }
    }
}

// MARK: - Media Library

private extension HLPermission {

    static func mediaLibraryStatus() -> HLPermissionStatus {
        switch MPMediaLibrary.authorizationStatus() {
        case .authorized:       return .authorized
        case .denied:           return .denied
        case .restricted:       return .restricted
        case .notDetermined:    return .notDetermined
        @unknown default:       return .notDetermined
        }
    }

    static func requestMediaLibrary(completion: @escaping (HLPermissionStatus) -> Void) {
        let current = mediaLibraryStatus()
        guard current == .notDetermined else {
            DispatchQueue.main.async { completion(current) }
            return
        }
        MPMediaLibrary.requestAuthorization { status in
            let result: HLPermissionStatus
            switch status {
            case .authorized:       result = .authorized
            case .denied:           result = .denied
            case .restricted:       result = .restricted
            case .notDetermined:    result = .notDetermined
            @unknown default:       result = .notDetermined
            }
            DispatchQueue.main.async { completion(result) }
        }
    }
}

// MARK: - Tracking (IDFA, iOS 14+)

private extension HLPermission {

    static func trackingStatus() -> HLPermissionStatus {
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .authorized:           return .authorized
            case .denied:               return .denied
            case .restricted:           return .restricted
            case .notDetermined:        return .notDetermined
            @unknown default:           return .notDetermined
            }
        }
        return .authorized // iOS 14 以下默认可追踪
    }

    static func requestTracking(completion: @escaping (HLPermissionStatus) -> Void) {
        if #available(iOS 14, *) {
            let current = trackingStatus()
            guard current == .notDetermined else {
                DispatchQueue.main.async { completion(current) }
                return
            }
            ATTrackingManager.requestTrackingAuthorization { status in
                let result: HLPermissionStatus
                switch status {
                case .authorized:       result = .authorized
                case .denied:           result = .denied
                case .restricted:       result = .restricted
                case .notDetermined:    result = .notDetermined
                @unknown default:       result = .notDetermined
                }
                DispatchQueue.main.async { completion(result) }
            }
        } else {
            DispatchQueue.main.async { completion(.authorized) }
        }
    }
}
