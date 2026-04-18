import SwiftUI

struct TelemetryGrid: View {
    var body: some View {
        GeometryReader { proxy in
            let columns = max(Int(proxy.size.width / 28), 8)
            let rows = max(Int(proxy.size.height / 28), 8)

            VStack(spacing: 10) {
                ForEach(0..<rows, id: \.self) { _ in
                    HStack(spacing: 12) {
                        ForEach(0..<columns, id: \.self) { _ in
                            Text("+")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(KairOSColors.grid.opacity(0.55))
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }
}

struct HatchMarks: View {
    let flipped: Bool

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<8, id: \.self) { _ in
                Rectangle()
                    .fill(KairOSColors.chrome)
                    .frame(width: 34, height: 3)
                    .rotationEffect(.degrees(flipped ? -24 : 24))
            }
        }
    }
}

struct BarcodeStrip: View {
    var body: some View {
        Text("|||| ||| |||||| || ||||| |||")
            .font(KairOSTypography.barcode)
            .lineLimit(1)
            .foregroundStyle(KairOSColors.chrome)
            .minimumScaleFactor(0.5)
    }
}

struct TelemetryRule: View {
    var body: some View {
        Rectangle()
            .fill(KairOSColors.chrome)
            .frame(height: 3)
    }
}
