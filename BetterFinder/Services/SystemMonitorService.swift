import Foundation
import IOKit

@Observable
final class SystemMonitorService {
    // MARK: - Configuration

    var refreshInterval: TimeInterval = 1.0

    // MARK: - CPU

    var cpuUsagePercent: Double = 0
    var cpuUserPercent: Double = 0
    var cpuSystemPercent: Double = 0
    var cpuIdlePercent: Double = 0
    var processCount: Int = 0

    // MARK: - Memory

    var memoryTotal: UInt64 = 0
    var memoryUsed: UInt64 = 0
    var memoryFree: UInt64 = 0
    var memoryWired: UInt64 = 0
    var memoryCompressed: UInt64 = 0
    var swapUsed: UInt64 = 0

    // MARK: - GPU

    var gpuUsagePercent: Double = 0
    var gpuAvailable: Bool = false

    // MARK: - Battery

    var batteryAvailable: Bool = false
    var batteryChargePercent: Int = 0
    var batteryIsCharging: Bool = false
    var batteryIsPluggedIn: Bool = false
    var batteryTimeRemaining: Int = 0 // minutes
    var batteryCycleCount: Int = 0

    // MARK: - Disk I/O

    var diskReadRate: UInt64 = 0
    var diskWriteRate: UInt64 = 0
    var diskBytesRead: UInt64 = 0
    var diskBytesWritten: UInt64 = 0

    // MARK: - Network

    var netInRate: UInt64 = 0
    var netOutRate: UInt64 = 0
    var netBytesIn: UInt64 = 0
    var netBytesOut: UInt64 = 0

    // MARK: - System

    var uptime: TimeInterval = 0
    var uptimeFormatted: String = ""
    var loadAverages: (Double, Double, Double) = (0, 0, 0)

    // MARK: - Private Delta State

    private var prevCPUTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?
    private var prevDiskRead: UInt64 = 0
    private var prevDiskWritten: UInt64 = 0
    private var prevNetIn: UInt64 = 0
    private var prevNetOut: UInt64 = 0
    private var prevTimestamp: Date?
    private var monitorTask: Task<Void, Never>?

    // MARK: - Lifecycle

    func startMonitoring() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: .seconds(self?.refreshInterval ?? 1.0))
            }
        }
    }

    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
    }

    // MARK: - Refresh

    func refresh() {
        refreshCPU()
        refreshMemory()
        refreshGPU()
        refreshBattery()
        refreshDiskIO()
        refreshNetworkIO()
        refreshUptime()
        refreshLoadAverages()
        refreshProcessCount()
    }

    // MARK: - CPU

    private func refreshCPU() {
        var loadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &loadInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let user = UInt64(loadInfo.cpu_ticks.0)   // CPU_STATE_USER
        let system = UInt64(loadInfo.cpu_ticks.1)  // CPU_STATE_SYSTEM
        let idle = UInt64(loadInfo.cpu_ticks.2)    // CPU_STATE_IDLE
        let nice = UInt64(loadInfo.cpu_ticks.3)    // CPU_STATE_NICE

        if let prev = prevCPUTicks {
            let dUser = user - prev.user
            let dSystem = system - prev.system
            let dIdle = idle - prev.idle
            let dNice = nice - prev.nice
            let total = Double(dUser + dSystem + dIdle + dNice)

            if total > 0 {
                cpuUserPercent = Double(dUser + dNice) / total * 100
                cpuSystemPercent = Double(dSystem) / total * 100
                cpuIdlePercent = Double(dIdle) / total * 100
                cpuUsagePercent = 100 - cpuIdlePercent
            }
        }

        prevCPUTicks = (user, system, idle, nice)
    }

    // MARK: - Memory

    private func refreshMemory() {
        memoryTotal = ProcessInfo.processInfo.physicalMemory

        var vmInfo = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &vmInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)
        let free = UInt64(vmInfo.free_count) * pageSize
        let wired = UInt64(vmInfo.wire_count) * pageSize
        let compressed = UInt64(vmInfo.compressor_page_count) * pageSize
        let active = UInt64(vmInfo.active_count) * pageSize
        let inactive = UInt64(vmInfo.inactive_count) * pageSize
        let speculative = UInt64(vmInfo.speculative_count) * pageSize

        memoryFree = free + inactive + speculative
        memoryWired = wired
        memoryCompressed = compressed
        memoryUsed = active + wired + compressed

        // Swap
        var swapUsage = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &swapUsage, &swapSize, nil, 0) == 0 {
            swapUsed = swapUsage.xsu_used
        }
    }

    // MARK: - GPU

    private func refreshGPU() {
        let matching = IOServiceMatching("IOAccelerator")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            gpuAvailable = false
            return
        }
        defer { IOObjectRelease(iterator) }

        var entry = IOIteratorNext(iterator)
        guard entry != 0 else {
            gpuAvailable = false
            return
        }
        defer { IOObjectRelease(entry) }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = properties?.takeRetainedValue() as? [String: Any] else {
            gpuAvailable = false
            return
        }

        if let perfStats = dict["PerformanceStatistics"] as? [String: Any] {
            // Try multiple known key names
            let utilization: Int? =
                perfStats["GPU Core Utilization"] as? Int ??
                perfStats["GPU Activity(%)"] as? Int ??
                perfStats["gpuCoreUtilizationPercent"] as? Int

            if let util = utilization {
                gpuAvailable = true
                // IOKit often reports as a fixed-point value scaled to 10000000 (100%)
                if util > 100 {
                    gpuUsagePercent = Double(util) / 10_000_000.0 * 100
                } else {
                    gpuUsagePercent = Double(util)
                }
            } else {
                gpuAvailable = false
            }
        } else {
            gpuAvailable = false
        }

        // Release any additional entries
        entry = IOIteratorNext(iterator)
        while entry != 0 {
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }
    }

    // MARK: - Battery

    private func refreshBattery() {
        let matching = IOServiceMatching("AppleSmartBattery")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)

        guard service != 0 else {
            batteryAvailable = false
            return
        }
        defer { IOObjectRelease(service) }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = properties?.takeRetainedValue() as? [String: Any] else {
            batteryAvailable = false
            return
        }

        batteryAvailable = true
        batteryChargePercent = dict["CurrentCapacity"] as? Int ?? 0
        batteryIsCharging = dict["IsCharging"] as? Bool ?? false
        batteryIsPluggedIn = dict["ExternalConnected"] as? Bool ?? false
        batteryTimeRemaining = dict["TimeRemaining"] as? Int ?? 0
        batteryCycleCount = dict["CycleCount"] as? Int ?? 0
    }

    // MARK: - Disk I/O

    private func refreshDiskIO() {
        let matching = IOServiceMatching("IOBlockStorageDriver")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }

        var totalRead: UInt64 = 0
        var totalWritten: UInt64 = 0

        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = properties?.takeRetainedValue() as? [String: Any],
               let stats = dict["Statistics"] as? [String: Any] {
                totalRead += stats["Bytes (Read)"] as? UInt64 ?? 0
                totalWritten += stats["Bytes (Write)"] as? UInt64 ?? 0
            }
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }

        let now = Date()
        if let prevTime = prevTimestamp {
            let elapsed = now.timeIntervalSince(prevTime)
            if elapsed > 0 {
                diskReadRate = totalRead > prevDiskRead ? UInt64(Double(totalRead - prevDiskRead) / elapsed) : 0
                diskWriteRate = totalWritten > prevDiskWritten ? UInt64(Double(totalWritten - prevDiskWritten) / elapsed) : 0
            }
        }

        diskBytesRead = totalRead
        diskBytesWritten = totalWritten
        prevDiskRead = totalRead
        prevDiskWritten = totalWritten
        prevTimestamp = now
    }

    // MARK: - Network I/O

    private func refreshNetworkIO() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = cursor {
            if addr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                let data = unsafeBitCast(addr.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
                totalIn += UInt64(data.pointee.ifi_ibytes)
                totalOut += UInt64(data.pointee.ifi_obytes)
            }
            cursor = addr.pointee.ifa_next
        }

        let now = Date()
        if let prevTime = prevTimestamp {
            let elapsed = now.timeIntervalSince(prevTime)
            if elapsed > 0 && prevNetIn > 0 {
                netInRate = totalIn > prevNetIn ? UInt64(Double(totalIn - prevNetIn) / elapsed) : 0
                netOutRate = totalOut > prevNetOut ? UInt64(Double(totalOut - prevNetOut) / elapsed) : 0
            }
        }

        netBytesIn = totalIn
        netBytesOut = totalOut
        prevNetIn = totalIn
        prevNetOut = totalOut
        // Note: prevTimestamp is already set by refreshDiskIO; if disk is called first it's fine
        if prevTimestamp == nil { prevTimestamp = now }
    }

    // MARK: - Uptime

    private func refreshUptime() {
        uptime = ProcessInfo.processInfo.systemUptime
        let totalSeconds = Int(uptime)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            uptimeFormatted = "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            uptimeFormatted = "\(hours)h \(minutes)m"
        } else {
            uptimeFormatted = "\(minutes)m"
        }
    }

    // MARK: - Load Averages

    private func refreshLoadAverages() {
        var loads = [Double](repeating: 0, count: 3)
        getloadavg(&loads, 3)
        loadAverages = (loads[0], loads[1], loads[2])
    }

    // MARK: - Process Count

    private func refreshProcessCount() {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
        var size: Int = 0
        sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0)
        processCount = size / MemoryLayout<kinfo_proc>.stride
    }

    // MARK: - Formatting Helpers

    static func formattedRate(_ bytesPerSec: UInt64) -> String {
        let value = Double(bytesPerSec)
        if value < 1024 {
            return "\(Int(value)) B/s"
        } else if value < 1024 * 1024 {
            return String(format: "%.1f KB/s", value / 1024)
        } else if value < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", value / (1024 * 1024))
        } else {
            return String(format: "%.1f GB/s", value / (1024 * 1024 * 1024))
        }
    }

    static func formattedBytes(_ bytes: UInt64) -> String {
        let value = Double(bytes)
        if value < 1024 {
            return "\(bytes) B"
        } else if value < 1024 * 1024 {
            return String(format: "%.1f KB", value / 1024)
        } else if value < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", value / (1024 * 1024))
        } else {
            return String(format: "%.2f GB", value / (1024 * 1024 * 1024))
        }
    }
}
