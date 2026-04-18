import Foundation

enum KairOSSound: String, CaseIterable {
    case accessGranted = "AccessGranted.mp3"
    case aliceSendMessage = "AliceSendMessage.mp3"
    case areYouSure = "AreYouSure.mp3"
    case disappointingFailure = "DISAPPOINTING_FAILURE.mp3"
    case fileBack = "FileBack.mp3"
    case fileDirectoryOpen = "FileDirectoryOpen.mp3"
    case fileFolderOpen = "FileFolderOpen.mp3"
    case fileRead = "FileRead.mp3"
    case keyType1 = "KeyType1.mp3"
    case keyType2 = "KeyType2.mp3"
    case keyType3 = "KeyType3.mp3"
    case keyType4 = "KeyType4.mp3"
    case lowPower = "LowPower.mp3"
    case oldDataUnpackProcessing = "OldDataUnpackProcessing.mp3"
    case radarPing = "RadarPing.mp3"
    case reminder = "Reminder.mp3"
    case tadaSuccess = "TadaSuccess.mp3"
    case userSendMessage = "UserSendMessage.mp3"
    case warningUI = "WarningUI.mp3"
    case yesSound = "YesSound.mp3"
    case archivistFileWindowClose = "archivist_file_window_close.wav"
    case commandLineClick1 = "command_line_click#1.wav"
    case commandLineClick2 = "command_line_click#2.wav"
    case commandLineClick3 = "command_line_click#3.wav"
    case commandLineClick4 = "command_line_click#4.wav"
    case commandLineClick5 = "command_line_click#5.wav"
    // Calling sounds
    case ringtone = "ringtone.mp3"
    case hangupNormal = "hangup_normal.mp3"
    case hangupLostConnection = "hangup_lostconnection.mp3"
    case callFailTone = "callfailtone.mp3"
    case callFailMessage = "callfailmessage.mp3"
    case dial0 = "Dial_0.mp3"
    case dial1 = "Dial_1.mp3"
    case dial2 = "Dial_2.mp3"
    case dial3 = "Dial_3.mp3"
    case dial4 = "Dial_4.mp3"
    case dial5 = "Dial_5.mp3"
    case dial6 = "Dial_6.mp3"
    case dial7 = "Dial_7.mp3"
    case dial8 = "Dial_8.mp3"
    case dial9 = "Dial_9.mp3"

    var resourceName: String {
        (rawValue as NSString).deletingPathExtension
    }

    var fileExtension: String {
        (rawValue as NSString).pathExtension
    }
}

enum KairOSSoundCatalog {
    static let buttonClickCycle: [KairOSSound] = [
        .commandLineClick1,
        .commandLineClick2,
        .commandLineClick3,
        .commandLineClick4,
        .commandLineClick5
    ]

    static let messageSounds: [String: KairOSSound] = [
        "user_send": .userSendMessage,
        "alice_send": .aliceSendMessage,
        "incoming_ping": .radarPing
    ]

    static let backupSounds: [String: KairOSSound] = [
        "prompt": .areYouSure,
        "success": .tadaSuccess,
        "failure": .disappointingFailure,
        "processing": .oldDataUnpackProcessing
    ]

    static let systemSounds: [String: KairOSSound] = [
        "activate_success": .accessGranted,
        "confirm": .yesSound,
        "warning": .warningUI,
        "reminder": .reminder,
        "low_power": .lowPower
    ]

    static let fileSounds: [String: KairOSSound] = [
        "open_folder": .fileFolderOpen,
        "open_directory": .fileDirectoryOpen,
        "read": .fileRead,
        "back": .fileBack,
        "close": .archivistFileWindowClose
    ]

    static let callingSounds: [String: KairOSSound] = [
        "ringtone": .ringtone,
        "hangup_normal": .hangupNormal,
        "hangup_lost_connection": .hangupLostConnection,
        "call_fail_tone": .callFailTone,
        "call_fail_message": .callFailMessage
    ]

    static let dialTones: [Int: KairOSSound] = [
        0: .dial0,
        1: .dial1,
        2: .dial2,
        3: .dial3,
        4: .dial4,
        5: .dial5,
        6: .dial6,
        7: .dial7,
        8: .dial8,
        9: .dial9
    ]

    static let allBundled = KairOSSound.allCases

    // Reserved placeholders for future sound drops so call sites can remain stable.
    static let futureSlots = [
        "custom_system_1",
        "custom_system_2",
        "custom_alert_1",
        "custom_ui_1"
    ]
}
