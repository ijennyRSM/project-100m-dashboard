import Foundation

/// Fictional presentation fixtures. Never written to HealthKit, a user's plan, or cloud storage.
struct SampleActivity: Identifiable {
    let id: String
    let name: String
    let time: String
    let title: String
    let symbol: String
    let description: String
    let summary: String
    var stats: [StatItem] {
        switch id {
        case "run": return [StatItem(label: "ระยะทาง", value: "3.2 km"), StatItem(label: "Pace", value: "7:30 /km"), StatItem(label: "เวลา", value: "24 นาที")]
        case "walk": return [StatItem(label: "ระยะทาง", value: "2.1 km"), StatItem(label: "เวลา", value: "30 นาที")]
        default: return [StatItem(label: "ท่าฝึก", value: "4 ท่า"), StatItem(label: "เวลา", value: "35 นาที")]
        }
    }
    static let examples = [
        SampleActivity(id: "run", name: "เมย์", time: "วันนี้ 07:20 · เวลาสมมติ", title: "Morning Easy Run", symbol: "figure.run", description: "กลับมาวิ่งเบา ๆ ทีละก้าว วันนี้อากาศดี", summary: "3.2 km · 24 นาที"),
        SampleActivity(id: "walk", name: "ต้น", time: "เมื่อวาน 18:10 · เวลาสมมติ", title: "Evening Walk", symbol: "figure.walk", description: "ปิดวันด้วยการเดินสบาย ๆ", summary: "2.1 km · 30 นาที"),
        SampleActivity(id: "strength", name: "พลอย", time: "เมื่อวาน 16:00 · เวลาสมมติ", title: "Strength Foundation", symbol: "dumbbell", description: "ค่อย ๆ สร้างความแข็งแรง เน้นท่าที่ควบคุมได้", summary: "4 ท่า · 35 นาที")
    ]
}

struct SampleProgram: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let symbol: String
    static let examples = [
        SampleProgram(id: "sprint100", name: "100M — The Comeback", summary: "กลับมาสร้างความเร็ว · 12 blocks · 60 sessions", symbol: "figure.run"),
        SampleProgram(id: "run5k", name: "5K Foundation", summary: "เริ่มจากวิ่งสลับเดิน ตามจังหวะของคุณ", symbol: "shoeprints.fill"),
        SampleProgram(id: "run10k", name: "10K Progression", summary: "แนวคิดโปรแกรม · ยังไม่มี prescription ที่ผ่านการทบทวน", symbol: "point.topleft.down.to.point.bottomright.curvepath"),
        SampleProgram(id: "strength", name: "Strength Foundation", summary: "ฝึกท่าหลัก สร้างพื้นฐานที่มั่นคง", symbol: "dumbbell"),
        SampleProgram(id: "wellness", name: "Active Wellness", summary: "เดิน เคลื่อนไหว และฟื้นฟู", symbol: "leaf")
    ]
}
