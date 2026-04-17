import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var events: [CalendarEvent] = []
    @State private var isLoading = false
    @State private var showingAddEvent = false
    @State private var newEventTitle = ""
    @State private var newEventDescription = ""
    @State private var newEventStartTime = Date()
    @State private var newEventEndTime = Date().addingTimeInterval(3600)
    @State private var newEventLocation = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CALENDAR")
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
                                Text(event.title)
                                    .font(KairOSTypography.mono)
                                    .foregroundStyle(KairOSColors.led)
                                if !event.description.isEmpty {
                                    Text(event.description)
                                        .font(KairOSTypography.body)
                                }
                                Text(formatDateRange(event.startTime, event.endTime))
                                    .font(KairOSTypography.mono)
                                    .foregroundStyle(KairOSColors.chrome.opacity(0.6))
                                if !event.location.isEmpty {
                                    Text(event.location)
                                        .font(KairOSTypography.mono)
                                        .foregroundStyle(KairOSColors.chrome.opacity(0.6))
                                }
                            }
                            .padding(12)
                            .background(KairOSColors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(KairOSColors.chrome, lineWidth: 1)
                            )
                            .onTapGesture {
                                appState.soundManager.playSubtleClick()
                                // TODO: Show event details
                            }
                        }
                    }
                }
            }
        }
        .panelChrome()
        .overlay(alignment: .bottomTrailing) {
            Button("+") {
                appState.soundManager.playClick()
                showingAddEvent = true
            }
            .font(KairOSTypography.hero)
            .foregroundStyle(KairOSColors.chrome)
            .padding()
            .background(KairOSColors.background)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(KairOSColors.chrome, lineWidth: 1)
            )
            .padding()
        }
        .sheet(isPresented: $showingAddEvent) {
            VStack(alignment: .leading, spacing: 16) {
                Text("ADD EVENT")
                    .font(KairOSTypography.hero)
                TextField("TITLE", text: $newEventTitle)
                    .textFieldStyle(IndustrialTextFieldStyle())
                TextField("DESCRIPTION", text: $newEventDescription, axis: .vertical)
                    .textFieldStyle(IndustrialTextFieldStyle())
                    .lineLimit(3...6)
                DatePicker("START TIME", selection: $newEventStartTime)
                    .font(KairOSTypography.mono)
                DatePicker("END TIME", selection: $newEventEndTime)
                    .font(KairOSTypography.mono)
                TextField("LOCATION", text: $newEventLocation)
                    .textFieldStyle(IndustrialTextFieldStyle())
                HStack {
                    Button("CANCEL") {
                        appState.soundManager.playClick()
                        showingAddEvent = false
                    }
                    .buttonStyle(HeaderButtonChrome())
                    Button("SAVE") {
                        appState.soundManager.playClick()
                        addEvent()
                    }
                    .buttonStyle(HeaderButtonChrome())
                }
            }
            .padding()
            .background(KairOSColors.background)
        }
        .onAppear {
            loadEvents()
        }
    }

    private func loadEvents() {
        isLoading = true
        Task {
            do {
                events = try await fetchEventsFromNode()
            } catch {
                print("Failed to load events: \(error)")
            }
            isLoading = false
        }
    }

    private func addEvent() {
        Task {
            do {
                let newEvent = CalendarEvent(
                    id: UUID().uuidString,
                    title: newEventTitle,
                    description: newEventDescription,
                    startTime: Int64(newEventStartTime.timeIntervalSince1970),
                    endTime: Int64(newEventEndTime.timeIntervalSince1970),
                    location: newEventLocation,
                    attendees: "",
                    createdBy: "ios",
                    createdAt: Int64(Date().timeIntervalSince1970)
                )
                _ = try await createEventOnNode(newEvent)
                newEventTitle = ""
                newEventDescription = ""
                newEventLocation = ""
                showingAddEvent = false
                loadEvents()
            } catch {
                print("Failed to add event: \(error)")
            }
        }
    }

    private func fetchEventsFromNode() async throws -> [CalendarEvent] {
        // TODO: Implement actual API call to Node
        return []
    }

    private func createEventOnNode(_ event: CalendarEvent) async throws {
        // TODO: Implement actual API call to Node
    }

    private func formatDateRange(_ startTime: Int64, _ endTime: Int64) -> String {
        let start = Date(timeIntervalSince1970: TimeInterval(startTime))
        let end = Date(timeIntervalSince1970: TimeInterval(endTime))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct CalendarEvent {
    let id: String
    let title: String
    let description: String
    let startTime: Int64
    let endTime: Int64
    let location: String
    let attendees: String
    let createdBy: String
    let createdAt: Int64
}
