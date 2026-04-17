import SwiftUI

struct NotesAppView: View {
    @StateObject private var api: KairOSAPIImpl
    @State private var notes: [Note] = []
    @State private var newNoteTitle = ""
    @State private var newNoteContent = ""
    @State private var showingAddNote = false
    
    init(api: KairOSAPIImpl) {
        _api = StateObject(wrappedValue: api)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("NOTES TERMINAL")
                    .font(KairOSTypography.title)
                    .foregroundStyle(KairOSColors.chrome)
                Spacer()
                Button("ADD") {
                    showingAddNote = true
                }
                .buttonStyle(HeaderButtonChrome())
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(notes) { note in
                        NoteRow(note: note, api: api)
                    }
                }
            }
        }
        .panelChrome()
        .onAppear {
            loadNotes()
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(api: api, onSave: loadNotes)
        }
    }
    
    private func loadNotes() {
        guard let data = api.readFile(named: "notes.json"),
              let notesData = try? JSONDecoder().decode([Note].self, from: data) else {
            notes = []
            return
        }
        notes = notesData.sorted { $0.createdAt > $1.createdAt }
    }
}

struct NoteRow: View {
    let note: Note
    let api: KairOSAPIImpl
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title)
                    .font(KairOSTypography.header)
                    .foregroundStyle(KairOSColors.chrome)
                Spacer()
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(KairOSTypography.mono)
                    .foregroundStyle(KairOSColors.muted)
            }
            
            Text(note.content)
                .font(KairOSTypography.mono)
                .foregroundStyle(KairOSColors.chrome)
                .lineLimit(3)
        }
        .padding(12)
        .background(KairOSColors.background)
        .overlay(
            Rectangle()
                .stroke(KairOSColors.grid, lineWidth: 1)
        )
    }
}

struct AddNoteView: View {
    let api: KairOSAPIImpl
    let onSave: () -> Void
    
    @State private var title = ""
    @State private var content = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Title", text: $title)
                    .textFieldStyle(IndustrialTextFieldStyle())
                
                TextEditor(text: $content)
                    .background(KairOSColors.background)
                    .overlay(
                        Rectangle()
                            .stroke(KairOSColors.chrome, lineWidth: 1)
                    )
                
                HStack {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .buttonStyle(HeaderButtonChrome())
                    
                    Button("SAVE") {
                        saveNote()
                    }
                    .buttonStyle(HeaderButtonChrome())
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
            .padding()
            .navigationTitle("NEW NOTE")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveNote() {
        let newNote = Note(
            id: UUID().uuidString,
            title: title,
            content: content,
            createdAt: Date()
        )
        
        var notes: [Note] = []
        if let data = api.readFile(named: "notes.json"),
           let existingNotes = try? JSONDecoder().decode([Note].self, from: data) {
            notes = existingNotes
        }
        
        notes.append(newNote)
        
        do {
            let data = try JSONEncoder().encode(notes)
            try api.writeFile(named: "notes.json", data: data)
            onSave()
            dismiss()
        } catch {
            // Handle error
        }
    }
}

struct Note: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
}
