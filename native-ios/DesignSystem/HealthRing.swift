import SwiftUI

enum WellnessMetric: String, CaseIterable, Identifiable {
    case sleep = "Sleep", recovery = "Recovery", strain = "Strain"
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .sleep: return .indigo
        case .recovery: return P100Theme.accent
        case .strain: return .orange
        }
    }
    var symbol: String {
        switch self {
        case .sleep: return "moon.zzz"
        case .recovery: return "heart"
        case .strain: return "flame"
        }
    }
}

/// Presentation states only. Numeric results require a reviewed, versioned model in M2.
enum WellnessState {
    case missing, insufficientBaseline, provisional(Double), available(Double)
    var value: Double? {
        switch self {
        case .missing, .insufficientBaseline: return nil
        case .provisional(let value), .available(let value): return value.isFinite ? min(100, max(0, value)) : nil
        }
    }
    var caption: String {
        switch self {
        case .missing: return "ยังไม่มีคะแนน"
        case .insufficientBaseline: return "ข้อมูลฐานยังไม่พอ"
        case .provisional: return "ค่าประเมินเบื้องต้น"
        case .available: return "มีข้อมูลพร้อม"
        }
    }
}

struct HealthRing: View {
    let metric: WellnessMetric
    let state: WellnessState
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(metric.color.opacity(0.16), lineWidth: 8)
                if let value = state.value {
                    Circle().trim(from: 0, to: value / 100)
                        .stroke(metric.color, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                }
                VStack(spacing: 3) {
                    Image(systemName: metric.symbol).font(.caption).foregroundStyle(metric.color)
                    Text(state.value.map { String(format: "%.0f", $0) } ?? "—").font(.title2.bold()).monospacedDigit()
                }
            }.frame(width: 88, height: 88)
            Text(metric.rawValue).font(.subheadline.bold())
            Text(state.caption).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(.vertical, 8).frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.rawValue), \(state.caption)")
        .accessibilityValue(state.value.map { String(format: "%.0f จาก 100", $0) } ?? "ยังไม่คำนวณ")
        .accessibilityHint("เปิดรายละเอียดและข้อมูลที่ใช้")
        .accessibilityIdentifier("ring-\(metric.rawValue.lowercased())")
    }
}

#Preview("Sample states only") {
    ScrollView {
        VStack {
            Text("ตัวอย่างข้อมูลสมมติ · ไม่ใช่คะแนนสุขภาพจริง")
            HealthRing(metric: .sleep, state: .missing)
            HealthRing(metric: .recovery, state: .insufficientBaseline)
            HealthRing(metric: .sleep, state: .provisional(72))
            HealthRing(metric: .strain, state: .available(48))
        }.padding()
    }
}
