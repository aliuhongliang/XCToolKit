//
//  HLNetworkInfo.swift
//  XCToolkit
//
//  本地网络信息获取，基于 SystemConfiguration
//  包含：IP、子网掩码、网关、WiFi SSID/BSSID、所有网卡信息
//
//  注意：
//  获取 WiFi SSID 需要在 Info.plist 中开启 Access WiFi Information entitlement
//  并在 Signing & Capabilities 中添加 Access WiFi Information

import Foundation
import SystemConfiguration.CaptiveNetwork
import Darwin

public struct HLNetworkInfo {

    private init() {}

    // MARK: - WiFi Info

    /// 当前连接的 WiFi 名称（SSID）
    /// 需要 Access WiFi Information entitlement
    public static var currentWiFiSSID: String? {
        return wifiInfo()?[kCNNetworkInfoKeySSID as String] as? String
    }

    /// 当前连接的 WiFi BSSID（路由器 MAC 地址）
    public static var currentBSSID: String? {
        return wifiInfo()?[kCNNetworkInfoKeyBSSID as String] as? String
    }

    // MARK: - IP & Network

    /// 当前 WiFi 网卡 IP 地址
    public static var currentIPAddress: String? {
        return address(for: "en0")
    }

    /// 当前蜂窝网络 IP 地址
    public static var currentCellularIPAddress: String? {
        return address(for: "pdp_ip0")
    }

    /// 当前子网掩码
    public static var currentSubnetMask: String? {
        return netmask(for: "en0")
    }


    // MARK: - All Interfaces

    /// 所有网卡的 IP 信息
    public static var allInterfaceAddresses: [HLInterfaceInfo] {
        var results: [HLInterfaceInfo] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return [] }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            let addr = current.pointee.ifa_addr.pointee

            // 只处理 IPv4 和 IPv6，且排除 loopback
            if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                if (flags & IFF_LOOPBACK) == 0 {
                    let name = String(cString: current.pointee.ifa_name)
                    if let ip = ipString(from: current.pointee.ifa_addr),
                       let mask = ipString(from: current.pointee.ifa_netmask) {
                        let isIPv6 = addr.sa_family == UInt8(AF_INET6)
                        results.append(HLInterfaceInfo(
                            name: name,
                            ip: ip,
                            netmask: mask,
                            isIPv6: isIPv6
                        ))
                    }
                }
            }
            ptr = current.pointee.ifa_next
        }
        return results
    }

    // MARK: - Private Helpers

    private static func wifiInfo() -> [String: Any]? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
        for interface in interfaces {
            if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
                return info
            }
        }
        return nil
    }

    private static func address(for interface: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while let current = ptr {
            if String(cString: current.pointee.ifa_name) == interface,
               current.pointee.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                return ipString(from: current.pointee.ifa_addr)
            }
            ptr = current.pointee.ifa_next
        }
        return nil
    }

    private static func netmask(for interface: String) -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while let current = ptr {
            if String(cString: current.pointee.ifa_name) == interface,
               current.pointee.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                return ipString(from: current.pointee.ifa_netmask)
            }
            ptr = current.pointee.ifa_next
        }
        return nil
    }

    private static func ipString(from addr: UnsafeMutablePointer<sockaddr>?) -> String? {
        guard let addr = addr else { return nil }
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        guard getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                          &hostname, socklen_t(hostname.count),
                          nil, 0, NI_NUMERICHOST) == 0 else { return nil }
        return String(cString: hostname)
    }
}

// MARK: - HLInterfaceInfo

public struct HLInterfaceInfo {
    /// 网卡名称（如 en0、pdp_ip0）
    public let name: String
    /// IP 地址
    public let ip: String
    /// 子网掩码
    public let netmask: String
    /// 是否是 IPv6
    public let isIPv6: Bool
}
