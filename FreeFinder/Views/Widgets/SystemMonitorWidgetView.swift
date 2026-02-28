import SwiftUI

struct SystemMonitorWidgetView: View {
    let currentDirectory: URL
    @Binding var widgetType: WidgetType
    @State private var service = SystemMonitorService()

    var body: some View {
        VStack(spacing: 0) {
            WidgetHeaderView(widgetType: $widgetType) {
                Menu {
                    ForEach([0.5, 1.0, 2.0, 5.0], id: \.self) { interval in
                        Button {
                            service.refreshInterval = interval
                        } label: {
                            HStack {
                                Text(interval == 0.5 ? "0.5s" : "\(Int(interval))s")
                                if service.refreshInterval == interval {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .fixedSize(horizontal: false, vertical: true)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    cpuSection
                    Divider()
                    memorySection
                    if service.gpuAvailable {
                        Divider()
                        gpuSection
                    }
                    if service.batteryAvailable {
                        Divider()
                        batterySection
                    }
                    Divider()
                    diskIOSection
                    Divider()
                    networkSection
                    Divider()
                    systemSection
                }
            }
        }
        .task {
            service.startMonitoring()
        }
        .onDisappear {
            service.stopMonitoring()
        }
    }

    // MARK: - CPU

    private var cpuSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("CPU")
            usageBar(percent: service.cpuUsagePercent, color: cpuColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
            infoRow("Usage", String(format: "%.1f%%", service.cpuUsagePercent))
            infoRow("User", String(format: "%.1f%%", service.cpuUserPercent))
            infoRow("System", String(format: "%.1f%%", service.cpuSystemPercent))
            infoRow("Processes", "\(service.processCount)")
            infoRow("Load Avg", String(format: "%.2f  %.2f  %.2f",
                                       service.loadAverages.0,
                                       service.loadAverages.1,
                                       service.loadAverages.2))
        }
    }

    private var cpuColor: Color {
        if service.cpuUsagePercent > 80 { return .red }
        if service.cpuUsagePercent > 50 { return .orange }
        return .green
    }

    // MARK: - Memory

    private var memorySection: some View {
        let usedPercent = service.memoryTotal > 0
            ? Double(service.memoryUsed) / Double(service.memoryTotal) * 100
            : 0

        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Memory")
            usageBar(percent: usedPercent, color: usedPercent > 80 ? .red : usedPercent > 60 ? .orange : .green)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
            infoRow("Used", SystemMonitorService.formattedBytes(service.memoryUsed))
            infoRow("Free", SystemMonitorService.formattedBytes(service.memoryFree))
            infoRow("Total", SystemMonitorService.formattedBytes(service.memoryTotal))
            infoRow("Wired", SystemMonitorService.formattedBytes(service.memoryWired))
            infoRow("Compressed", SystemMonitorService.formattedBytes(service.memoryCompressed))
            infoRow("Swap", SystemMonitorService.formattedBytes(service.swapUsed))
        }
    }

    // MARK: - GPU

    private var gpuSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("GPU")
            usageBar(percent: service.gpuUsagePercent, color: service.gpuUsagePercent > 80 ? .red : .blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
            infoRow("Usage", String(format: "%.1f%%", service.gpuUsagePercent))
        }
    }

    // MARK: - Battery

    private var batterySection: some View {
        let chargeColor: Color = service.batteryChargePercent < 20 ? .red :
                                 service.batteryChargePercent < 50 ? .orange : .green

        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Battery")
            usageBar(percent: Double(service.batteryChargePercent), color: chargeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
            infoRow("Charge", "\(service.batteryChargePercent)%")
            infoRow("Status", batteryStatusText)
            if service.batteryTimeRemaining > 0 {
                infoRow("Time Left", formatMinutes(service.batteryTimeRemaining))
            }
            infoRow("Cycles", "\(service.batteryCycleCount)")
        }
    }

    private var batteryStatusText: String {
        if service.batteryIsCharging { return "Charging" }
        if service.batteryIsPluggedIn { return "Plugged In" }
        return "On Battery"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    // MARK: - Disk I/O

    private var diskIOSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Disk I/O")
            infoRow("Read", SystemMonitorService.formattedRate(service.diskReadRate))
            infoRow("Write", SystemMonitorService.formattedRate(service.diskWriteRate))
            infoRow("Total Read", SystemMonitorService.formattedBytes(service.diskBytesRead))
            infoRow("Total Write", SystemMonitorService.formattedBytes(service.diskBytesWritten))
        }
    }

    // MARK: - Network

    private var networkSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Network")
            infoRow("Down", SystemMonitorService.formattedRate(service.netInRate))
            infoRow("Up", SystemMonitorService.formattedRate(service.netOutRate))
            infoRow("Total In", SystemMonitorService.formattedBytes(service.netBytesIn))
            infoRow("Total Out", SystemMonitorService.formattedBytes(service.netBytesOut))
        }
    }

    // MARK: - System

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("System")
            infoRow("Uptime", service.uptimeFormatted)
            infoRow("Load Avg", String(format: "%.2f / %.2f / %.2f",
                                       service.loadAverages.0,
                                       service.loadAverages.1,
                                       service.loadAverages.2))
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }

    private func usageBar(percent: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(nsColor: .controlBackgroundColor))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: max(0, geo.size.width * min(percent, 100) / 100))
            }
        }
        .frame(height: 6)
    }
}
