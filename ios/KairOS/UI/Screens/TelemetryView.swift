import SwiftUI

struct TelemetryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var events: [TelemetryEvent] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TELEMETRY")
                .font(KairOSTypography.hero)
                .fixedSize(horizontal: false, vertical: true)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: KairOSColors.chrome))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(events, id: \.id) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.eventType.uppercased())
                                    .font(KairOSTypography.mono)
                                    .foregroundStyle(KairOSColors.led)
                                Text(event.details ?? "")
                                    .font(KairOSTypography.body)
                                Text(formatTimestamp(event.timestamp))
                                    .font(KairOSTypography.mono)
                                    .foregroundStyle(KairOSColors.chrome.opacity(0.6))
                            }
                            .padding(12)
                            .background(KairOSColors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(KairOSColors.chrome, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .panelChrome()
        .onAppear {
            loadTelemetry()
        }
    }

    private func loadTelemetry() {
        isLoading = true
        Task {
            do {
                // Fetch telemetry from Node
                events = try await fetchTelemetryFromNode()
            } catch {
                print("Failed to load telemetry: \(error)")
            }
            isLoading = false
        }
    }

    private func fetchTelemetryFromNode() async throws -> [TelemetryEvent] {
        // TODO: Implement actual API call to Node
        return []
    }

    private func formatTimestamp(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TelemetryEvent {
    let id: Int64
    let eventType: String
    let details: String?
    let timestamp: Int64
}
