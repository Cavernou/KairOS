import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var events: [CalendarEvent] = []
    @State private var isLoading = false
    @State private var showingAddEvent = false
    @State private var showingEventDetails = false
    @State private var selectedEvent: CalendarEvent?
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
                                selectedEvent = event
                                showingEventDetails = true
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
        .sheet(isPresented: $showingEventDetails) {
            if let event = selectedEvent {
                eventDetailsSheet(event: event)
            }
        }
        .onAppear {
            loadEvents()
        }
    }

    private func eventDetailsSheet(event: CalendarEvent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EVENT DETAILS")
                .font(KairOSTypography.hero)
            Text(event.title)
                .font(KairOSTypography.header)
            if !event.description.isEmpty {
                Text(event.description)
                    .font(KairOSTypography.body)
            }
            Text(formatDateRange(event.startTime, event.endTime))
                .font(KairOSTypography.mono)
            if !event.location.isEmpty {
                Text("Location: \(event.location)")
                    .font(KairOSTypography.mono)
            }
            Button("CLOSE") {
                appState.soundManager.playClick()
                showingEventDetails = false
            }
            .buttonStyle(HeaderButtonChrome())
        }
        .padding()
        .background(KairOSColors.background)
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
        let url = URL(string: "http://\(appState.nodeHost):\(appState.nodePort)/mock/v1/calendar")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(CalendarResponse.self, from: data)
        return response.events
    }

    private func createEventOnNode(_ event: CalendarEvent) async throws {
        let url = URL(string: "http://\(appState.nodeHost):\(appState.nodePort)/mock/v1/calendar")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "id": event.id,
            "title": event.title,
            "description": event.description,
            "start_time": event.startTime,
            "end_time": event.endTime,
            "location": event.location,
            "attendees": event.attendees,
            "created_by": event.createdBy,
            "created_at": event.createdAt
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
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

struct CalendarResponse: Codable {
    let events: [CalendarEvent]
}

struct CalendarEvent: Codable {
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
