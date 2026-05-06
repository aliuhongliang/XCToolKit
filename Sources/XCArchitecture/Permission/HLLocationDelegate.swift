//
//  HLLocationDelegate.swift
//  XCToolkit
//
//  定位权限内部代理，业务层无需感知

import CoreLocation

/// 内部使用，封装 CLLocationManager 的代理回调
final class HLLocationDelegate: NSObject, CLLocationManagerDelegate {

    var completion: ((HLPermissionStatus) -> Void)?

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handle(status: status, manager: manager)
    }

    // iOS 14+
    @available(iOS 14, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handle(status: manager.authorizationStatus, manager: manager)
    }

    private func handle(status: CLAuthorizationStatus, manager: CLLocationManager) {
        // notDetermined 说明还没有弹窗，继续等待
        guard status != .notDetermined else { return }

        let result: HLPermissionStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            result = .authorized
        case .denied:
            result = .denied
        case .restricted:
            result = .restricted
        default:
            result = .notDetermined
        }

        DispatchQueue.main.async {
            self.completion?(result)
            self.completion = nil
        }
    }
}
