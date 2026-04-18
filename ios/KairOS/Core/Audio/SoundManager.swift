import AVFoundation
import Foundation
import SwiftUI

@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    var isEnabled = true
    var ambientEnabled = true
    var volume: Float = 1.0
    var ambientVolume: Float = 0.3

    private var players: [KairOSSound: AVAudioPlayer] = [:]
    private var nextClickIndex = 0
    
    // Placeholder/temp sounds - user can replace these later
    private var tempSounds: [String: AVAudioPlayer] = [:]
    private var ambientPlayer: AVAudioPlayer?
    private var ambientTimer: Timer?

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func play(_ sound: KairOSSound) {
        guard isEnabled else { return }

        do {
            let player = try player(for: sound)
            player.volume = volume
            player.currentTime = 0
            player.play()
        } catch {
            #if DEBUG
            print("KairOS sound load failed for \(sound.rawValue): \(error)")
            #endif
        }
    }

    func playClick() {
        let sound = KairOSSoundCatalog.buttonClickCycle[nextClickIndex % KairOSSoundCatalog.buttonClickCycle.count]
        nextClickIndex += 1
        play(sound)
    }
    
    // Play a temp/placeholder sound by name
    func playTempSound(_ name: String) {
        guard isEnabled else { return }
        
        if let player = tempSounds[name] {
            player.volume = volume * 0.5 // Temp sounds at half volume
            player.currentTime = 0
            player.play()
        }
    }
    
    // Register a temp sound (user can add these later)
    func registerTempSound(_ name: String, url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            tempSounds[name] = player
            print("Registered temp sound: \(name)")
        } catch {
            print("Failed to load temp sound \(name): \(error)")
        }
    }
    
    // Play subtle ambient sound
    func playAmbient() {
        guard ambientEnabled else { return }
        
        // Try to load ambient sound if not already loaded
        if ambientPlayer == nil {
            if let url = Bundle.main.url(forResource: "ambient_hum", withExtension: "mp3", subdirectory: "Sounds/SystemSounds") {
                do {
                    ambientPlayer = try AVAudioPlayer(contentsOf: url)
                    ambientPlayer?.numberOfLoops = -1 // Loop indefinitely
                    ambientPlayer?.volume = ambientVolume
                } catch {
                    print("Failed to load ambient sound: \(error)")
                }
            }
        }
        
        ambientPlayer?.play()
    }
    
    func stopAmbient() {
        ambientPlayer?.stop()
    }
    
    func setAmbientVolume(_ volume: Float) {
        ambientVolume = max(0, min(1, volume))
        ambientPlayer?.volume = ambientVolume
    }

    private func player(for sound: KairOSSound) throws -> AVAudioPlayer {
        if let existing = players[sound] {
            return existing
        }

        guard let url = Bundle.main.url(
            forResource: sound.resourceName,
            withExtension: sound.fileExtension,
            subdirectory: "Sounds/SystemSounds"
        ) else {
            throw NSError(domain: "SoundManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing bundled sound \(sound.rawValue)"])
        }

        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        players[sound] = player
        return player
    }
    
    // Play subtle click sound for background interactions
    func playSubtleClick() {
        guard isEnabled else { return }

        // Use a softer version of click sounds
        let sound = KairOSSoundCatalog.buttonClickCycle[nextClickIndex % KairOSSoundCatalog.buttonClickCycle.count]
        nextClickIndex += 1

        do {
            let player = try player(for: sound)
            player.volume = volume * 0.4 // 40% volume for subtle clicks
            player.currentTime = 0
            player.play()
        } catch {
            // Silent fallback
        }
    }

    // Handle app scene phase changes
    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Resume ambient if it was playing before
            if ambientEnabled && ambientPlayer != nil {
                ambientPlayer?.play()
            }
        case .background, .inactive:
            // Pause ambient when app goes to background
            stopAmbient()
        @unknown default:
            break
        }
    }
}
