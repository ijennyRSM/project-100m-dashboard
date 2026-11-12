import Foundation

/// Training library. Prescriptions are a faithful port of the reviewed web definitions in
/// `v2-data.js` (`templates`, `sA`, `sB`, `strengthA`, `strengthB`, `buildSessions`).
/// Do not add or alter prescriptions here without a reviewed source; `run10k` is listed but
/// unavailable because no reviewed 10K prescription exists on the web or in native.
enum TrainingCatalog {
    static let templates: [PlanTemplate] = [
        PlanTemplate(id: "sprint100", name: "100M — The Comeback", category: "Speed", blocks: 12,
                     description: "กลับมาวิ่ง 100 เมตรอย่างค่อยเป็นค่อยไป พร้อมเวทขาและ Easy Run",
                     symbol: "figure.run", isAvailable: true),
        PlanTemplate(id: "run5k", name: "5K Foundation", category: "Running", blocks: 8,
                     description: "พัฒนาจาก Run–Walk สู่การวิ่ง 5 กม. แบบสบาย",
                     symbol: "shoeprints.fill", isAvailable: true),
        PlanTemplate(id: "run10k", name: "10K Progression", category: "Running", blocks: 0,
                     description: "ต่อยอดจาก 5K สู่ 10K",
                     symbol: "point.topleft.down.to.point.bottomright.curvepath", isAvailable: false,
                     availabilityNote: "ยังไม่มี prescription ที่ผ่านการทบทวน จึงยังเริ่มแผนนี้ไม่ได้"),
        PlanTemplate(id: "strength", name: "Strength Foundation", category: "Strength", blocks: 8,
                     description: "สร้างพื้นฐานความแข็งแรงด้วยท่าหลักที่ทำได้ในยิม",
                     symbol: "dumbbell", isAvailable: true),
        PlanTemplate(id: "wellness", name: "Active Wellness", category: "Wellness", blocks: 6,
                     description: "เดิน เคลื่อนไหว เวทเบา และฟื้นฟูร่างกาย",
                     symbol: "leaf", isAvailable: true)
    ]

    static func template(_ id: String) -> PlanTemplate? { templates.first { $0.id == id } }

    private static let sprintA: [(Int, Int, String)] = [
        (4, 20, "60–70%"), (5, 20, "65–75%"), (5, 20, "70–80%"), (3, 20, "เบา"), (4, 20, "75–85%"), (5, 20, "80–85%"),
        (5, 30, "80–90%"), (3, 20, "เบา"), (4, 30, "85–90%"), (4, 30, "90–95%"), (3, 40, "90–95%"), (3, 20, "เบา")
    ]
    private static let sprintB: [(Int, Int, String)] = [
        (4, 20, "60–70%"), (4, 20, "70%"), (4, 30, "70–80%"), (3, 20, "เบา"), (4, 30, "75–85%"), (4, 30, "80–85%"),
        (4, 40, "80–90%"), (3, 30, "เบา"), (3, 50, "85–90%"), (3, 60, "85–90%"), (3, 60, "90–95%"), (1, 100, "ทดสอบเมื่อพร้อม")
    ]
    static let strengthA = [
        StrengthExercise(name: "Goblet Squat", sets: 2, reps: "8"),
        StrengthExercise(name: "Romanian Deadlift", sets: 2, reps: "8"),
        StrengthExercise(name: "Calf Raise", sets: 2, reps: "12"),
        StrengthExercise(name: "Plank", sets: 2, reps: "20–30 วินาที")
    ]
    static let strengthB = [
        StrengthExercise(name: "Split Squat", sets: 2, reps: "8/ข้าง"),
        StrengthExercise(name: "Glute Bridge", sets: 2, reps: "12"),
        StrengthExercise(name: "Hamstring Curl", sets: 2, reps: "10"),
        StrengthExercise(name: "Side Plank", sets: 2, reps: "20 วินาที/ข้าง")
    ]

    private static func withSets(_ list: [StrengthExercise], _ sets: Int) -> [StrengthExercise] {
        list.map { StrengthExercise(name: $0.name, sets: sets, reps: $0.reps) }
    }

    private static func session(_ block: Int, _ slot: Int, _ title: String, _ kind: SessionKind, _ summary: String,
                                _ details: String, _ components: SessionComponents, _ minutes: Int) -> TrainingSession {
        TrainingSession(key: "w\(block)-\(slot)", block: block, slot: slot, title: title, kind: kind, summary: summary,
                        details: details, components: components, minutes: minutes)
    }

    /// Ordered sessions for a template; empty for unknown or unavailable templates.
    static func sessions(for templateId: String) -> [TrainingSession] {
        guard let template = template(templateId), template.isAvailable else { return [] }
        var result: [TrainingSession] = []
        for w in 1...template.blocks {
            switch templateId {
            case "sprint100":
                let a = sprintA[w - 1], b = sprintB[w - 1], rest = w == 4 || w == 8
                let low = w < 3 ? 15 : w < 5 ? 20 : w < 7 ? 25 : w < 9 ? 25 : 30
                let long = w < 3 ? 20 : w < 5 ? 25 : w < 7 ? 30 : w < 9 ? 30 : 40
                let sets = rest || w == 12 ? 1 : w < 5 ? 2 : 3
                result.append(session(w, 1, "Sprint A + Strength A", .sprint,
                    "Sprint \(a.0) × \(a.1)m · \(a.2) + เวทขา",
                    "วอร์มอัพ 15–20 นาที, A-March/A-Skip, ฝึกเร่งจากท่ายืน; พักเต็ม 2–3 นาที/เที่ยว ก่อนเวทขา",
                    SessionComponents(sprint: SprintPrescription(reps: a.0, meters: a.1, effort: a.2), strength: withSets(strengthA, sets)), 55))
                result.append(session(w, 2, "Easy Run", .easy, "\(low)–\(low + 5) นาที · พูดเป็นประโยคได้",
                    "วิ่งช้า หรือสลับวิ่ง–เดินได้ตามการฟื้นตัว หลีกเลี่ยงการฝืนเพซ", SessionComponents(duration: low), low))
                result.append(session(w, 3, "Strength B", .strength, "เวทขา \(sets) เซต/ท่า",
                    "น้ำหนักปานกลาง เหลือแรงประมาณ 2–3 ครั้งต่อเซต; ไม่เล่นจนหมดแรง",
                    SessionComponents(strength: withSets(strengthB, sets)), 40))
                result.append(session(w, 4, w == 12 ? "100M Time Trial" : "Sprint B", .sprint,
                    w == 12 ? "ทดสอบ 100m หากพร้อม" : "\(b.0) × \(b.1)m · \(b.2)",
                    w == 12 ? "ทดสอบได้เมื่อแข็งแรง ฟื้นตัวดี และไม่มีอาการเจ็บ; จับเวลาด้วยวิธีที่สม่ำเสมอ หากไม่พร้อมให้เลื่อน"
                            : "วอร์มอัพ 15–20 นาที; เริ่มจากท่ายืน ไม่ต้องใช้รองเท้าตะปู; พัก 2–6 นาทีหรือจนฟื้นตัว",
                    SessionComponents(sprint: SprintPrescription(reps: b.0, meters: b.1, effort: b.2)), 40))
                result.append(session(w, 5, "Easy Run / Run–Walk", .easy, "\(long)–\(long + 5) นาที · สบาย",
                    "ออกกำลังระดับที่ยังสนทนาได้ ถ้าไม่พร้อมให้ลดเวลา หรือเลือกเดินฟื้นตัว", SessionComponents(duration: long), long))
            case "run5k":
                let a = min(35, 14 + (w - 1) * 3), b = min(45, 20 + (w - 1) * 4)
                result.append(session(w, 1, "Run–Walk Foundation", .easy, "\(a) นาที",
                    "วิ่งช้าสลับเดินได้; เน้นความสบายและความต่อเนื่อง", SessionComponents(duration: a), a))
                result.append(session(w, 2, "Strength & Mobility", .strength, "Squat / Bridge / Calf / Core",
                    "เริ่ม 2 เซตต่อท่าและพักเมื่อจำเป็น", SessionComponents(strength: withSets(strengthA, 2)), 30))
                result.append(session(w, 3, "Long Easy Run", .easy, "\(b) นาที",
                    "วิ่งช้าสม่ำเสมอหรือเดินสลับ ถ้าเหนื่อยผิดปกติให้ลดระยะ", SessionComponents(duration: b), b))
            case "strength":
                let sets = w <= 2 ? 2 : w == 8 ? 2 : 3
                result.append(session(w, 1, "Full Body A", .strength, "Squat / Hinge / Calf / Core",
                    "ใช้ท่าที่ควบคุมได้และเพิ่มน้ำหนักอย่างค่อยเป็นค่อยไป", SessionComponents(strength: withSets(strengthA, sets)), 45))
                result.append(session(w, 2, "Walk & Mobility", .walk, "เดิน 20–30 นาที",
                    "วันฟื้นตัวแบบเคลื่อนไหว; ไม่จำเป็นต้องเดินเร็ว", SessionComponents(duration: 25), 25))
                result.append(session(w, 3, "Full Body B", .strength, "Single-leg / Bridge / Hamstring / Core",
                    "หยุดก่อนถึงภาวะหมดแรง", SessionComponents(strength: withSets(strengthB, sets)), 45))
            default: // wellness
                let walk = 20 + min(10, w * 2)
                result.append(session(w, 1, "Active Walk", .walk, "เดิน \(walk) นาที",
                    "รักษาความสบายและสังเกตการฟื้นตัว", SessionComponents(duration: walk), 30))
                result.append(session(w, 2, "Mobility & Strength", .strength, "เวทเบา / ท่าขยับข้อต่อ",
                    "ปรับตามความพร้อม ไม่ฝืนอาการเจ็บ", SessionComponents(strength: withSets(strengthB, 2)), 30))
                result.append(session(w, 3, "Easy Cardio", .easy, "20–35 นาที",
                    "วิ่งช้า/เดิน/ปั่นตามสะดวก", SessionComponents(duration: 20 + min(15, w * 2)), 30))
            }
        }
        return result
    }
}
