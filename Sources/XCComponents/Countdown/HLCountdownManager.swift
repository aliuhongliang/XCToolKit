//
//  HLCountdownManager.swift
//  XCToolkit
//
//  Created by wintop on 2026/4/14.
//

import UIKit

class HLCountdownManager: NSObject {
    static let shared = HLCountdownManager()

    private let totalDuration: Double = 60
    private var startTimes: [HLCountdownKey: CFTimeInterval] = [:]
    private var timers: [HLCountdownKey: Timer] = [:]
    
    // 每个 key 对应一组 observers
    private var observers: [HLCountdownKey: [(Int) -> Void]] = [:]

    func isCounting(for key: HLCountdownKey) -> Bool {
        guard let start = startTimes[key] else { return false }
        return start > 0 && (CACurrentMediaTime() - start) < totalDuration
    }

    func begin(for key: HLCountdownKey) {
        guard !isCounting(for: key) else { return }
        startTimes[key] = CACurrentMediaTime()
        startTimer(for: key)
    }

    func stop(for key: HLCountdownKey) {
        timers[key]?.invalidate()
        timers[key] = nil
        startTimes[key] = nil
    }

    /// 注册回调，进入页面时调用，返回当前剩余秒数（用于立即刷新 UI）
    @discardableResult
    func observe(for key: HLCountdownKey, handler: @escaping (Int) -> Void) -> Int {
        observers[key, default: []].append(handler)
        // 返回当前剩余，方便进入页面时立刻渲染
        return remaining(for: key)
    }

    func removeObservers(for key: HLCountdownKey) {
        observers[key] = nil
    }

    func remaining(for key: HLCountdownKey) -> Int {
        guard let start = startTimes[key] else { return 0 }
        return max(Int(totalDuration - (CACurrentMediaTime() - start)), 0)
    }
}

private extension HLCountdownManager {

    func startTimer(for key: HLCountdownKey) {
        timers[key]?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick(for: key)
        }
        timers[key] = timer
        timer.fire()
    }

    func tick(for key: HLCountdownKey) {
        guard let start = startTimes[key] else { return }
        let elapsed = CACurrentMediaTime() - start
        let remaining = max(Int(totalDuration - elapsed), 0)

        self.observers[key]?.forEach { $0(remaining) }

        if remaining == 0 {
            stop(for: key)
        }
    }
}
