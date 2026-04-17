import SwiftUI
import PhotosUI

struct MediaView: View {
    @EnvironmentObject private var appState: AppState
    @State private var mediaItems: [MediaItem] = []
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

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
                                // TODO: Show media preview
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
        .onAppear {
            loadMedia()
        }
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
            // TODO: Upload to Node
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
        // TODO: Implement actual API call to Node
        return []
    }

    private func deleteMediaOnNode(_ id: String) async throws {
        // TODO: Implement actual API call to Node
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct MediaItem {
    let id: String
    let name: String
    let type: String
    let filePath: String
    let size: Int64
    let uploadedBy: String
    let uploadedAt: Int64
}
