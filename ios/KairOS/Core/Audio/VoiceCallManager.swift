import Foundation
import AVFoundation
import CallKit
import UIKit
import Combine

@MainActor
final class VoiceCallManager: NSObject, ObservableObject {
    @Published var currentCall: VoiceCall?
    @Published var isMicrophoneMuted = false
    @Published var isSpeakerEnabled = false
    @Published var callHistory: [VoiceCallRecord] = []
    
    private let callController = CXCallController()
    private let provider = CXProvider(configuration: .init())
    private var audioEngine: AVAudioEngine?
    private var currentCallUUID: UUID?
    private var ringtonePlayer: AVAudioPlayer?
    private var dialTonePlayer: AVAudioPlayer?
    
    enum CallState {
        case ringing
        case connecting
        case connected
        case ended
        case failed

        var description: String {
            switch self {
            case .ringing: return "RINGING"
            case .connecting: return "CONNECTING"
            case .connected: return "CONNECTED"
            case .ended: return "ENDED"
            case .failed: return "FAILED"
            }
        }
    }

    enum HangupType {
        case normal
        case lostConnection
    }
    
    override init() {
        super.init()
        setupCallProvider()
        setupAudioSession()
    }
    
    // MARK: - Call Management
    
    func startCall(to kairNumber: String) async throws {
        guard currentCall == nil else {
            throw VoiceCallError.callInProgress
        }
        
        let callUUID = UUID()
        currentCallUUID = callUUID
        
        // Create CallKit transaction
        let handle = CXHandle(type: .generic, value: kairNumber)
        let startCallAction = CXStartCallAction(call: callUUID, handle: handle)
        let transaction = CXTransaction(action: startCallAction)
        
        try await callController.request(transaction)
        
        // Update local state
        currentCall = VoiceCall(
            id: callUUID,
            remoteKairNumber: kairNumber,
            state: .connecting,
            startTime: Date(),
            duration: 0
        )
        
        // Initialize audio
        try await setupAudioForCall()
        
        // Start ringtone
        playRingtone()
        
        // Simulate connection (in real implementation, this would connect via node)
        try await simulateCallConnection(kairNumber: kairNumber)
    }
    
    func endCall(hangupType: HangupType = .normal) async throws {
        guard let call = currentCall else {
            throw VoiceCallError.noActiveCall
        }
        
        let endCallAction = CXEndCallAction(call: call.id)
        let transaction = CXTransaction(action: endCallAction)
        
        try await callController.request(transaction)
        
        // Stop ringtone
        stopRingtone()
        
        // Play appropriate hangup sound
        playHangupSound(type: hangupType)
        
        await cleanupCall(call)
    }
    
    func acceptIncomingCall(from kairNumber: String, callUUID: UUID) async throws {
        guard currentCall == nil else {
            throw VoiceCallError.callInProgress
        }
        
        currentCall = VoiceCall(
            id: callUUID,
            remoteKairNumber: kairNumber,
            state: .ringing,
            startTime: Date(),
            duration: 0
        )
        
        try await setupAudioForCall()
        
        // Accept the call via CallKit
        let answerCallAction = CXAnswerCallAction(call: callUUID)
        let transaction = CXTransaction(action: answerCallAction)
        try await callController.request(transaction)
    }
    
    func rejectIncomingCall(callUUID: UUID) async throws {
        let endCallAction = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: endCallAction)
        try await callController.request(transaction)
    }
    
    // MARK: - Audio Management
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothHFP, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupAudioForCall() async throws {
        audioEngine = AVAudioEngine()
        
        let inputNode = audioEngine!.inputNode
        let outputNode = audioEngine!.outputNode
        
        // Configure audio format for voice calls
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)
        
        // Connect input to output for speakerphone mode
        audioEngine!.connect(inputNode, to: outputNode, format: format)
        
        try audioEngine!.start()
    }
    
    private func cleanupAudio() async {
        audioEngine?.stop()
        audioEngine = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Call State Management
    
    private func simulateCallConnection(kairNumber: String) async throws {
        guard currentCall != nil else { return }
        
        // Simulate ringing phase
        currentCall?.state = .ringing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Simulate connection
        currentCall?.state = .connecting
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Connected
        currentCall?.state = .connected
        
        // Start duration timer
        startDurationTimer()
    }
    
    private func cleanupCall(_ call: VoiceCall) async {
        currentCall?.state = .ended
        currentCall?.endTime = Date()
        
        // Calculate final duration
        if let startTime = currentCall?.startTime {
            currentCall?.duration = Date().timeIntervalSince(startTime)
        }
        
        // Add to call history
        if let call = currentCall {
            let record = VoiceCallRecord(
                id: call.id,
                remoteKairNumber: call.remoteKairNumber,
                startTime: call.startTime ?? Date(),
                endTime: call.endTime ?? Date(),
                duration: call.duration,
                isIncoming: false
            )
            callHistory.insert(record, at: 0)
        }
        
        // Cleanup resources
        await cleanupAudio()
        currentCall = nil
        currentCallUUID = nil
        
        // Stop duration timer
        stopDurationTimer()
    }
    
    // MARK: - Duration Timer
    
    private var durationTimer: Timer?
    
    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCallDuration()
            }
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    private func updateCallDuration() {
        guard let call = currentCall,
              let startTime = call.startTime else { return }
        
        currentCall?.duration = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Audio Controls

    func toggleMicrophone() async throws {
        guard currentCall != nil else {
            throw VoiceCallError.noActiveCall
        }

        isMicrophoneMuted.toggle()

        // Apply mute state to audio engine
        audioEngine?.inputNode.volume = isMicrophoneMuted ? 0.0 : 1.0
    }

    // MARK: - Calling Sound Effects

    private func playRingtone() {
        guard let sound = KairOSSoundCatalog.callingSounds["ringtone"] else { return }

        do {
            guard let url = Bundle.main.url(
                forResource: sound.resourceName,
                withExtension: sound.fileExtension,
                subdirectory: "Sounds/SystemSounds"
            ) else { return }

            ringtonePlayer = try AVAudioPlayer(contentsOf: url)
            ringtonePlayer?.numberOfLoops = -1 // Loop indefinitely
            ringtonePlayer?.volume = 1.0
            ringtonePlayer?.play()
        } catch {
            print("Failed to play ringtone: \(error)")
        }
    }

    private func stopRingtone() {
        ringtonePlayer?.stop()
        ringtonePlayer = nil
    }

    private func playHangupSound(type: HangupType) {
        let soundKey: String
        switch type {
        case .normal:
            soundKey = "hangup_normal"
        case .lostConnection:
            soundKey = "hangup_lost_connection"
        }

        guard let sound = KairOSSoundCatalog.callingSounds[soundKey] else { return }

        do {
            guard let url = Bundle.main.url(
                forResource: sound.resourceName,
                withExtension: sound.fileExtension,
                subdirectory: "Sounds/SystemSounds"
            ) else { return }

            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.play()
        } catch {
            print("Failed to play hangup sound: \(error)")
        }
    }

    func playCallFailSequence() {
        // Play call fail tone first
        guard let toneSound = KairOSSoundCatalog.callingSounds["call_fail_tone"] else { return }

        do {
            guard let toneUrl = Bundle.main.url(
                forResource: toneSound.resourceName,
                withExtension: toneSound.fileExtension,
                subdirectory: "Sounds/SystemSounds"
            ) else { return }

            let tonePlayer = try AVAudioPlayer(contentsOf: toneUrl)
            tonePlayer.volume = 1.0
            tonePlayer.play()

            // Play call fail message after tone finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + tonePlayer.duration) {
                guard let messageSound = KairOSSoundCatalog.callingSounds["call_fail_message"] else { return }

                do {
                    guard let messageUrl = Bundle.main.url(
                        forResource: messageSound.resourceName,
                        withExtension: messageSound.fileExtension,
                        subdirectory: "Sounds/SystemSounds"
                    ) else { return }

                    let messagePlayer = try AVAudioPlayer(contentsOf: messageUrl)
                    messagePlayer.volume = 1.0
                    messagePlayer.play()
                } catch {
                    print("Failed to play call fail message: \(error)")
                }
            }
        } catch {
            print("Failed to play call fail tone: \(error)")
        }
    }

    func playDialTone(digit: Int) {
        guard let sound = KairOSSoundCatalog.dialTones[digit] else { return }

        do {
            guard let url = Bundle.main.url(
                forResource: sound.resourceName,
                withExtension: sound.fileExtension,
                subdirectory: "Sounds/SystemSounds"
            ) else { return }

            dialTonePlayer = try AVAudioPlayer(contentsOf: url)
            dialTonePlayer?.numberOfLoops = -1 // Loop while held
            dialTonePlayer?.volume = 1.0
            dialTonePlayer?.play()
        } catch {
            print("Failed to play dial tone: \(error)")
        }
    }

    func stopDialTone() {
        dialTonePlayer?.stop()
        dialTonePlayer = nil
    }
    
    func toggleSpeaker() async throws {
        guard currentCall != nil else {
            throw VoiceCallError.noActiveCall
        }
        
        isSpeakerEnabled.toggle()
        
        // Configure audio session for speaker mode
        do {
            let audioSession = AVAudioSession.sharedInstance()
            let mode: AVAudioSession.Mode = isSpeakerEnabled ? .videoChat : .voiceChat
            try audioSession.setMode(mode)
            try audioSession.overrideOutputAudioPort(isSpeakerEnabled ? .speaker : .none)
        } catch {
            throw VoiceCallError.audioConfigurationFailed(error)
        }
    }
    
    // MARK: - CallKit Provider Setup
    
    private func setupCallProvider() {
        provider.setDelegate(self, queue: nil)
        
        provider.configuration.iconTemplateImageData = createCallIconData()
        provider.configuration.ringtoneSound = "default"
        provider.configuration.includesCallsInRecents = true
        provider.configuration.supportsVideo = false
        provider.configuration.maximumCallsPerCallGroup = 1
    }
    
    private func createCallIconData() -> Data {
        // Create a simple call icon for CallKit
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Draw KairOS-style call icon
            context.cgContext.setFillColor(UIColor.systemYellow.cgColor)
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            
            context.cgContext.setFillColor(UIColor.black.cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 10, y: 10, width: 20, height: 20))
        }
        
        return image.pngData() ?? Data()
    }
    
    // MARK: - Error Types
    
    enum VoiceCallError: LocalizedError {
        case callInProgress
        case noActiveCall
        case audioConfigurationFailed(Error)
        case connectionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .callInProgress:
                return "Another call is already in progress"
            case .noActiveCall:
                return "No active call to end"
            case .audioConfigurationFailed(let error):
                return "Audio configuration failed: \(error.localizedDescription)"
            case .connectionFailed(let reason):
                return "Connection failed: \(reason)"
            }
        }
    }
}

// MARK: - Voice Call Models

struct VoiceCall: Identifiable {
    let id: UUID
    let remoteKairNumber: String
    var state: VoiceCallManager.CallState
    let startTime: Date?
    var endTime: Date?
    var duration: TimeInterval
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct VoiceCallRecord: Codable, Identifiable {
    let id: UUID
    let remoteKairNumber: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let isIncoming: Bool
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - CallKit Delegate

@MainActor
extension VoiceCallManager: CXProviderDelegate {
    nonisolated func providerDidReset(_ provider: CXProvider) {
        Task { @MainActor in
            currentCall = nil
            await cleanupAudio()
        }
    }
    
    private func provider(_ provider: CXProvider, perform action: CXStartCallAction) async {
        // Handle outgoing call initiated by system
        let kairNumber = action.handle.value
        do {
            try await startCall(to: kairNumber)
            action.fulfill()
        } catch {
            action.fail()
        }
    }
    
    private func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) async {
        // Handle incoming call answered by user
        guard currentCall != nil else {
            action.fail()
            return
        }
        
        currentCall?.state = .connected
        startDurationTimer()
        action.fulfill()
    }
    
    private func provider(_ provider: CXProvider, perform action: CXEndCallAction) async {
        // Handle call ended by user
        do {
            try await endCall()
            action.fulfill()
        } catch {
            action.fail()
        }
    }
    
    private func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) async {
        // Handle mute state change
        isMicrophoneMuted = action.isMuted
        action.fulfill()
    }
}
