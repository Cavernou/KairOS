import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var appState: AppState
    @State private var tasks: [Task] = []
    @State private var isLoading = false
    @State private var selectedTask: Task?
    @State private var showingTaskDetails = false
    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var newTaskDueDate = Date()
    @State private var newTaskPriority = "medium"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TASKS")
                .font(KairOSTypography.hero)
                .fixedSize(horizontal: false, vertical: true)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: KairOSColors.chrome))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(tasks, id: \.id) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(task.title)
                                        .font(KairOSTypography.mono)
                                        .foregroundStyle(KairOSColors.led)
                                    Spacer()
                                    Text(task.priority.uppercased())
                                        .font(KairOSTypography.mono)
                                        .foregroundStyle(priorityColor(task.priority))
                                }
                                if !task.description.isEmpty {
                                    Text(task.description)
                                        .font(KairOSTypography.body)
                                }
                                Text("Due: \(formatDate(task.dueDate))")
                                    .font(KairOSTypography.mono)
                                    .foregroundStyle(KairOSColors.chrome.opacity(0.6))
                            }
                            .padding(12)
                            .background(KairOSColors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(KairOSColors.chrome, lineWidth: 1)
                            )
                            .onTapGesture {
                                appState.soundManager.playSubtleClick()
                                selectedTask = task
                                showingTaskDetails = true
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
                showingAddTask = true
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
        .sheet(isPresented: $showingAddTask) {
            VStack(alignment: .leading, spacing: 16) {
                Text("ADD TASK")
                    .font(KairOSTypography.hero)
                TextField("TITLE", text: $newTaskTitle)
                    .textFieldStyle(IndustrialTextFieldStyle())
                TextField("DESCRIPTION", text: $newTaskDescription, axis: .vertical)
                    .textFieldStyle(IndustrialTextFieldStyle())
                    .lineLimit(3...6)
                DatePicker("DUE DATE", selection: $newTaskDueDate)
                    .font(KairOSTypography.mono)
                Picker("PRIORITY", selection: $newTaskPriority) {
                    Text("LOW").tag("low")
                    Text("MEDIUM").tag("medium")
                    Text("HIGH").tag("high")
                }
                .pickerStyle(SegmentedPickerStyle())
                HStack {
                    Button("CANCEL") {
                        appState.soundManager.playClick()
                        showingAddTask = false
                    }
                    .buttonStyle(HeaderButtonChrome())
                    Button("SAVE") {
                        appState.soundManager.playClick()
                        addTask()
                    }
                    .buttonStyle(HeaderButtonChrome())
                }
            }
            .padding()
            .background(KairOSColors.background)
        }
        .sheet(isPresented: $showingTaskDetails) {
            if let task = selectedTask {
                taskDetailsSheet(task: task)
            }
        }
        .onAppear {
            loadTasks()
        }
    }

    private func taskDetailsSheet(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TASK DETAILS")
                .font(KairOSTypography.hero)
            Text(task.title)
                .font(KairOSTypography.header)
            if !task.description.isEmpty {
                Text(task.description)
                    .font(KairOSTypography.body)
            }
            Text("Due: \(formatDate(task.dueDate))")
                .font(KairOSTypography.mono)
            Text("Priority: \(task.priority.uppercased())")
                .font(KairOSTypography.mono)
            Text("Status: \(task.status.uppercased())")
                .font(KairOSTypography.mono)
            Button("CLOSE") {
                appState.soundManager.playClick()
                showingTaskDetails = false
            }
            .buttonStyle(HeaderButtonChrome())
        }
        .padding()
        .background(KairOSColors.background)
    }

    private func loadTasks() {
        isLoading = true
        Task {
            do {
                tasks = try await fetchTasksFromNode()
            } catch {
                print("Failed to load tasks: \(error)")
            }
            isLoading = false
        }
    }

    private func addTask() {
        Task {
            do {
                let newTask = Task(
                    id: UUID().uuidString,
                    title: newTaskTitle,
                    description: newTaskDescription,
                    dueDate: Int64(newTaskDueDate.timeIntervalSince1970),
                    priority: newTaskPriority,
                    status: "pending",
                    createdBy: "ios",
                    createdAt: Int64(Date().timeIntervalSince1970),
                    completedAt: nil
                )
                _ = try await createTaskOnNode(newTask)
                newTaskTitle = ""
                newTaskDescription = ""
                showingAddTask = false
                loadTasks()
            } catch {
                print("Failed to add task: \(error)")
            }
        }
    }

    private func fetchTasksFromNode() async throws -> [Task] {
        let url = URL(string: "http://\(appState.nodeHost):\(appState.nodePort)/mock/v1/tasks")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TasksResponse.self, from: data)
        return response.tasks
    }

    private func createTaskOnNode(_ task: Task) async throws {
        let url = URL(string: "http://\(appState.nodeHost):\(appState.nodePort)/mock/v1/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "due_date": task.dueDate,
            "priority": task.priority,
            "status": task.status,
            "created_by": task.createdBy,
            "created_at": task.createdAt
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
        }
    }

    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "high":
            return KairOSColors.alert
        case "medium":
            return KairOSColors.led
        default:
            return KairOSColors.chrome
        }
    }
}

struct TasksResponse: Codable {
    let tasks: [Task]
}

struct Task: Codable {
    let id: String
    let title: String
    let description: String
    let dueDate: Int64
    let priority: String
    let status: String
    let createdBy: String
    let createdAt: Int64
    let completedAt: Int64?
}
