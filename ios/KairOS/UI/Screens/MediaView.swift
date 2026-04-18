import SwiftUI
import PhotosUI

struct MediaView: View {
    @EnvironmentObject private var appState: AppState
    @State private var mediaItems: [MediaItem] = []
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingMediaPreview = false
    @State private var selectedMediaItem: MediaItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MEDIA")
                .font(KairOSTypography.hero)
                .fixedSize(horizontal: false, vertical: true)

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: KairOSColors.chrome))
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach(mediaItems, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                ZStack {
                                    Rectangle()
                                        .fill(KairOSColors.chrome.opacity(0.2))
                                        .aspectRatio(1, contentMode: .fit)
                                    Text(item.type.uppercased())
                                        .font(KairOSTypography.mono)
                                        .foregroundStyle(KairOSColors.chrome)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                Text(item.name)
                                    .font(KairOSTypography.mono)
                                    .lineLimit(1)
                                Text(formatFileSize(item.size))
                                    .font(KairOSTypography.mono)
                                    .foregroundStyle(KairOSColors.chrome.opacity(0.6))
                            }
                            .onTapGesture {
                                appState.soundManager.playSubtleClick()
                                selectedMediaItem = item
                                showingMediaPreview = true
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    appState.soundManager.playClick()
                                    deleteMedia(item)
                                } label: {
                                    Label("DELETE", systemImage: "trash")
                                }
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
                showingImagePicker = true
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
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedPhotoItem,
            matching: .any(of: .images, .videos)
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let newItem = newItem {
                Task {
                    await uploadMedia(newItem)
                }
            }
        }
        .sheet(isPresented: $showingMediaPreview) {
            if let item = selectedMediaItem {
                mediaPreviewSheet(item: item)
            }
        }
        .onAppear {
            loadMedia()
        }
    }

    private func mediaPreviewSheet(item: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MEDIA PREVIEW")
                .font(KairOSTypography.hero)
            Text(item.name)
                .font(KairOSTypography.header)
            Text("Type: \(item.type.uppercased())")
                .font(KairOSTypography.mono)
            Text("Size: \(formatFileSize(item.size))")
                .font(KairOSTypography.mono)
            Text("Uploaded by: \(item.uploadedBy)")
                .font(KairOSTypography.mono)
            Text("Uploaded at: \(formatDate(item.uploadedAt))")
                .font(KairOSTypography.mono)
            Button("CLOSE") {
                appState.soundManager.playClick()
                showingMediaPreview = false
            }
            .buttonStyle(HeaderButtonChrome())
        }
        .padding()
        .background(KairOSColors.background)
    }

    private func loadMedia() {
        isLoading = true
        Task {
            do {
                mediaItems = try await fetchMediaFromNode()
            } catch {
                print("Failed to load media: \(error)")
            }
            isLoading = false
        }
    }

    private func uploadMedia(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let url = URL(string: "http://\(appState.nodeHost):\(appState.nodePort)/mock/v1/files/upload")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")

            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"upload_\(Date().timeIntervalSince1970).bin\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            appState.soundManager.play(.accessGranted)
            loadMedia()
        } catch {
            print("Failed to load media: \(error)")
            appState.soundManager.play(.warningUI)
        }
    }

    private func deleteMedia(_ item: MediaItem) {
        Task {
            do {
                _ = try await deleteMediaOnNode(item.id)
                appState.soundManager.play(.accessGranted)
                loadMedia()
            } catch {
                print("Failed to delete media: \(error)")
                appState.soundManager.play(.warningUI)
            }
        }
    }

    private func fetchMediaFromNode() async throws -> [MediaItem] {
        let url = URL(string: "http://\(appState.nodeHost):\(appState.nodePort)/mock/v1/files/browse")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MediaResponse.self, from: data)
        return response.files
    }

    private func deleteMediaOnNode(_ id: String) async throws {
        let url = URL(string: "http://\(appState.nodeHost):\(appState.nodePort)/mock/v1/files/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct MediaResponse: Codable {
    let files: [MediaItem]
}

struct MediaItem: Codable {
    let id: String
    let name: String
    let type: String
    let filePath: String
    let size: Int64
    let uploadedBy: String
    let uploadedAt: Int64
}
