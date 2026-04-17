import SwiftUI

struct NotesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var notes: [Note] = []
    @State private var isLoading = false
    @State private var showingAddNote = false
    @State private var newNoteTitle = ""
    @State private var newNoteContent = ""
    @State private var newNoteTags = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NOTES")
                .font(KairOSTypography.hero)
                .fixedSize(horizontal: false, vertical: true)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: KairOSColors.chrome))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(notes, id: \.id) { note in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(KairOSTypography.mono)
                                    .foregroundStyle(KairOSColors.led)
                                Text(note.content)
                                    .font(KairOSTypography.body)
                                    .lineLimit(3)
                                if !note.tags.isEmpty {
                                    Text(note.tags)
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
                                // TODO: Show note details
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
                showingAddNote = true
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
        .sheet(isPresented: $showingAddNote) {
            VStack(alignment: .leading, spacing: 16) {
                Text("ADD NOTE")
                    .font(KairOSTypography.hero)
                TextField("TITLE", text: $newNoteTitle)
                    .textFieldStyle(IndustrialTextFieldStyle())
                TextField("CONTENT", text: $newNoteContent, axis: .vertical)
                    .textFieldStyle(IndustrialTextFieldStyle())
                    .lineLimit(5...10)
                TextField("TAGS (comma separated)", text: $newNoteTags)
                    .textFieldStyle(IndustrialTextFieldStyle())
                HStack {
                    Button("CANCEL") {
                        appState.soundManager.playClick()
                        showingAddNote = false
                    }
                    .buttonStyle(HeaderButtonChrome())
                    Button("SAVE") {
                        appState.soundManager.playClick()
                        addNote()
                    }
                    .buttonStyle(HeaderButtonChrome())
                }
            }
            .padding()
            .background(KairOSColors.background)
        }
        .onAppear {
            loadNotes()
        }
    }

    private func loadNotes() {
        isLoading = true
        Task {
            do {
                notes = try await fetchNotesFromNode()
            } catch {
                print("Failed to load notes: \(error)")
            }
            isLoading = false
        }
    }

    private func addNote() {
        Task {
            do {
                let newNote = Note(
                    id: UUID().uuidString,
                    title: newNoteTitle,
                    content: newNoteContent,
                    tags: newNoteTags,
                    createdBy: "ios",
                    createdAt: Int64(Date().timeIntervalSince1970),
                    updatedAt: Int64(Date().timeIntervalSince1970)
                )
                _ = try await createNoteOnNode(newNote)
                newNoteTitle = ""
                newNoteContent = ""
                newNoteTags = ""
                showingAddNote = false
                loadNotes()
            } catch {
                print("Failed to add note: \(error)")
            }
        }
    }

    private func fetchNotesFromNode() async throws -> [Note] {
        // TODO: Implement actual API call to Node
        return []
    }

    private func createNoteOnNode(_ note: Note) async throws {
        // TODO: Implement actual API call to Node
    }
}

struct Note {
    let id: String
    let title: String
    let content: String
    let tags: String
    let createdBy: String
    let createdAt: Int64
    let updatedAt: Int64
}
