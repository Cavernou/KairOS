import SwiftUI

enum KairOSTypography {
    // Blueprint font mapping
    static let microTab = Font.custom("europa-grotesk-sh-bold", size: 12, relativeTo: .headline) // Navigation labels
    static let header = Font.custom("europa-grotesk-sh-bold", size: 16, relativeTo: .headline) // Headers
    static let mono = Font.custom("MIB", size: 14, relativeTo: .body) // Logs, metadata, file names
    static let title = Font.custom("HomeVideoBold", size: 28, relativeTo: .largeTitle) // Titles
    static let lcd = Font.custom("digital-7", size: 20, relativeTo: .title2) // Clocks, timers, counters
    static let barcode = Font.custom("code128", size: 28, relativeTo: .title2) // Barcodes
    static let hero = Font.custom("HomeVideoBold", size: 44, relativeTo: .largeTitle) // Hero branding
    static let branding = Font.custom("Redacted-Regular", size: 32, relativeTo: .largeTitle) // Industrial serif branding
}
