import SwiftUI

extension AttemptStatus {
    var label: String {
        switch self {
        case .completed: return "ฝึกครบ"
        case .partial: return "ทำบางส่วน"
        case .skipped: return "ข้าม"
        }
    }
    var symbol: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .skipped: return "arrow.uturn.forward.circle"
        }
    }
}

enum P100Format {
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600, m = total % 3600 / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}

struct SecondaryAction: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline)
            .padding(.horizontal, 20).padding(.vertical, 12).frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(P100Theme.accent)
            .background(P100Theme.accent.opacity(configuration.isPressed ? 0.16 : 0.08), in: Capsule())
            .overlay(Capsule().strokeBorder(P100Theme.accent.opacity(0.5)))
    }
}

/// Real next-session card for the active plan.
struct ActivePlanCard: View {
    @EnvironmentObject private var training: TrainingModel
    let plan: TrainingPlan
    let overview: PlanOverview

    var body: some View {
        P100Card {
            SectionHeading(title: TrainingCatalog.template(plan.templateId)?.name ?? plan.templateId,
                           subtitle: "ฝึกครบ \(overview.completed) · ข้าม \(overview.skipped) · ทั้งหมด \(overview.total) sessions")
            ProgressView(value: Double(overview.completed + overview.skipped), total: Double(max(overview.total, 1)))
                .accessibilityLabel("ความคืบหน้า \(overview.percent) เปอร์เซ็นต์")
            if let next = overview.next {
                Label(training.live?.key == next.key ? "กำลังฝึกค้างอยู่" : "ครั้งต่อไปของคุณ",
                      systemImage: "arrow.forward.circle.fill").font(.subheadline.bold()).foregroundStyle(P100Theme.accent)
                Text(next.title).font(.title2.bold()).accessibilityIdentifier("next-session-title")
                Text("Block \(next.block) · Session \(next.slot)\n\(next.summary)").foregroundStyle(.secondary)
                if overview.statusByKey[next.key] == .partial {
                    Label("ทำบางส่วนไว้แล้ว ทำต่อจากเดิมได้", systemImage: AttemptStatus.partial.symbol).font(.subheadline)
                }
                NavigationLink { LiveWorkoutScreen(startKey: next.key) } label: {
                    Label(training.live?.key == next.key ? "ทำ Live Workout ต่อ" : "เริ่ม Live Workout", systemImage: "play.fill")
                }.buttonStyle(PrimaryAction()).accessibilityIdentifier("start-live")
                NavigationLink { SessionDetailScreen(sessionKey: next.key) } label: {
                    Label("รายละเอียดและบันทึกแบบย่อ", systemImage: "list.bullet").frame(minHeight: 44)
                }.accessibilityIdentifier("open-next-session")
                Text("Session ไม่หมดอายุ แม้หยุดพักหลายวัน").font(.caption).foregroundStyle(.secondary)
            } else {
                Label("จบแผนนี้แล้ว ยินดีด้วย!", systemImage: "flag.checkered").font(.headline)
            }
        }
        // No container identifier here: it would override child IDs such as next-session-title (ADR-013).
    }
}

struct NoPlanCard: View {
    var body: some View {
        P100Card {
            SectionHeading(title: "ยังไม่ได้เลือกแผนฝึก", subtitle: "เลือกโปรแกรมแล้วเริ่มครั้งแรกได้เลย ข้อมูลเก็บในเครื่องนี้ก่อน")
            NavigationLink { TrainingLibraryScreen() } label: {
                Label("เลือกแผนฝึก", systemImage: "list.bullet.rectangle")
            }.buttonStyle(PrimaryAction()).accessibilityIdentifier("choose-plan")
        }
    }
}

struct TrainingLibraryScreen: View {
    var body: some View {
        P100Screen {
            SectionHeading(title: "Training library", subtitle: "โปรแกรมจากแผนเดิมบนเว็บ ไม่ผูกกับวันในสัปดาห์")
            TemplateList()
        }.navigationTitle("เลือกแผน").navigationBarTitleDisplayMode(.inline)
    }
}

struct TemplateList: View {
    var body: some View {
        ForEach(TrainingCatalog.templates) { template in
            NavigationLink { ProgramScreen(template: template) } label: {
                P100Card {
                    Label(template.name, systemImage: template.symbol).font(.headline)
                    Text(template.isAvailable
                         ? "\(template.description) · \(template.blocks) blocks · \(TrainingCatalog.sessions(for: template.id).count) sessions"
                         : template.availabilityNote ?? "ยังไม่พร้อม")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Label(template.isAvailable ? "ดูโปรแกรม" : "ยังเริ่มไม่ได้", systemImage: "chevron.right").font(.caption)
                }
            }.buttonStyle(.plain).accessibilityIdentifier("program-\(template.id)")
        }
    }
}

struct ProgramScreen: View {
    @EnvironmentObject private var training: TrainingModel
    let template: PlanTemplate
    @State private var confirmStart = false

    private var existing: TrainingPlan? { training.state.plans.last { $0.templateId == template.id } }
    private var sessions: [TrainingSession] { TrainingCatalog.sessions(for: template.id) }

    var body: some View {
        P100Screen {
            P100Card {
                Label(template.name, systemImage: template.symbol).font(.title2.bold())
                Text(template.description)
                Text("ฝึกครบ → Session ถัดไป\nทำบางส่วน → Session เดิม เก็บส่วนที่ทำแล้วไว้\nข้าม → ต้องยืนยันก่อนเสมอ")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if !template.isAvailable {
                StatusBanner(title: "ยังเริ่มโปรแกรมนี้ไม่ได้", message: template.availabilityNote ?? "", symbol: "hourglass")
            } else {
                if training.activePlan?.templateId == template.id {
                    StatusBanner(title: "เป็นแผนที่ใช้งานอยู่", message: "ฝึกต่อจากที่นี่ หรือจาก Today และ Train", symbol: "checkmark.seal")
                        .accessibilityIdentifier("plan-active")
                    NavigationLink { LiveWorkoutScreen(startKey: nil) } label: {
                        Label(training.live == nil ? "เริ่ม Live Workout ครั้งต่อไป" : "ทำ Live Workout ต่อ", systemImage: "play.fill")
                    }.buttonStyle(PrimaryAction()).accessibilityIdentifier("program-start-live")
                } else if let existing {
                    Button("กลับไปใช้แผนนี้ (ประวัติเดิมยังอยู่)") {
                        training.selectPlan(existing.id)
                    }.buttonStyle(SecondaryAction()).accessibilityIdentifier("resume-plan")
                }
                if training.activePlan?.templateId != template.id {
                    Button("เริ่มแผนนี้") {
                        if training.activePlan == nil { start() } else { confirmStart = true }
                    }.buttonStyle(PrimaryAction()).accessibilityIdentifier("start-plan")
                        .disabled(training.live != nil)
                    if training.live != nil {
                        Text("จบหรือยกเลิก Live Workout ที่ค้างอยู่ก่อนเปลี่ยนแผน").font(.caption).foregroundStyle(.secondary)
                    }
                }
                SectionHeading(title: "Block 1", subtitle: "\(template.blocks) blocks · \(sessions.count) sessions")
                ForEach(sessions.filter { $0.block == 1 }) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.title).font(.headline)
                        Text(session.summary).font(.subheadline).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if let message = training.errorMessage { Text(message).foregroundStyle(.red) }
        }.navigationTitle("โปรแกรม").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("เริ่ม \(template.name)?", isPresented: $confirmStart, titleVisibility: .visible) {
                Button("เริ่มแผนใหม่") { start() }
                Button("ยกเลิก", role: .cancel) {}
            } message: {
                Text("แผนปัจจุบันและประวัติจะยังอยู่ และกลับไปใช้ได้ภายหลัง")
            }
    }

    private func start() {
        training.startPlan(template.id)
    }
}

struct SessionStatusRow: View {
    let session: TrainingSession
    let status: AttemptStatus?
    let isNext: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status?.symbol ?? (isNext ? "arrow.forward.circle" : "circle"))
                .foregroundStyle(status == nil && !isNext ? Color.secondary : P100Theme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title).font(.headline)
                Text("Session \(session.slot) · \(session.summary)").font(.subheadline).foregroundStyle(.secondary)
                if let status { Text(status.label).font(.caption.bold()).foregroundStyle(P100Theme.accent) }
                else if isNext { Text("ครั้งต่อไป").font(.caption.bold()).foregroundStyle(P100Theme.accent) }
            }
            Spacer(minLength: 0)
        }.frame(minHeight: 44).accessibilityElement(children: .combine)
    }
}

struct PlanDetailScreen: View {
    @EnvironmentObject private var training: TrainingModel
    var body: some View {
        P100Screen {
            if let plan = training.activePlan, let overview = training.overview {
                SectionHeading(title: TrainingCatalog.template(plan.templateId)?.name ?? plan.templateId,
                               subtitle: "\(overview.percent)% · ฝึกครบ \(overview.completed)/\(overview.total)")
                ForEach(Array(Set(overview.sessions.map(\.block))).sorted(), id: \.self) { block in
                    P100Card {
                        Text("Block \(block)").font(.title3.bold())
                        ForEach(overview.sessions.filter { $0.block == block }) { session in
                            NavigationLink { SessionDetailScreen(sessionKey: session.key) } label: {
                                SessionStatusRow(session: session, status: overview.statusByKey[session.key],
                                                 isNext: overview.next?.key == session.key)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            } else {
                NoPlanCard()
            }
        }.navigationTitle("ทุก Session").navigationBarTitleDisplayMode(.inline)
    }
}

struct SessionDetailScreen: View {
    @EnvironmentObject private var training: TrainingModel
    let sessionKey: String
    @State private var showLog = false
    @State private var confirmSkip = false

    private var session: TrainingSession? { training.overview?.sessions.first { $0.key == sessionKey } }
    private var status: AttemptStatus? { training.overview?.statusByKey[sessionKey] }
    private var resolved: Bool { status == .completed || status == .skipped }

    var body: some View {
        P100Screen {
            if let session {
                Label("Block \(session.block) · Session \(session.slot)", systemImage: "figure.run")
                    .font(.caption.bold()).foregroundStyle(P100Theme.accent)
                Text(session.title).font(P100Type.hero)
                StatStrip(items: [StatItem(label: "เวลาโดยประมาณ", value: "\(session.minutes) นาที"),
                                  StatItem(label: "สถานะ", value: status?.label ?? "ยังไม่บันทึก")])
                P100Card {
                    SectionHeading(title: "สิ่งที่ต้องทำ", subtitle: session.summary)
                    Text(session.details)
                    if let sprint = session.components.sprint {
                        Divider()
                        Text("Sprint · \(sprint.reps) × \(sprint.meters)m · \(sprint.effort)")
                    }
                    if let duration = session.components.duration {
                        Divider()
                        Text("แอโรบิก · \(duration) นาที")
                    }
                    if let strength = session.components.strength, !strength.isEmpty {
                        Divider()
                        Text(strength.map { "\($0.name) · \($0.sets) × \($0.reps)" }.joined(separator: "\n"))
                    }
                }
                if resolved {
                    StatusBanner(title: "บันทึกแล้ว: \(status?.label ?? "")", message: "Session นี้ไม่ต้องทำซ้ำ", symbol: "checkmark.seal")
                } else {
                    NavigationLink { LiveWorkoutScreen(startKey: session.key) } label: {
                        Label("เริ่ม Live Workout", systemImage: "play.fill")
                    }.buttonStyle(PrimaryAction()).accessibilityIdentifier("detail-start-live")
                    Button("บันทึกแบบย่อ (ฝึกเสร็จแล้ว / ทำบางส่วน)") { showLog = true }
                        .buttonStyle(SecondaryAction()).accessibilityIdentifier("quick-log")
                    Button("ข้าม Session นี้…") { confirmSkip = true }
                        .frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("skip-session")
                }
                if let message = training.errorMessage { Text(message).foregroundStyle(.red) }
            } else {
                Text("ไม่พบ Session นี้ในแผนปัจจุบัน").foregroundStyle(.secondary)
            }
        }.navigationTitle("Session").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLog) { QuickLogSheet(sessionKey: sessionKey) }
            .confirmationDialog("ข้าม Session นี้?", isPresented: $confirmSkip, titleVisibility: .visible) {
                Button("ยืนยันข้าม", role: .destructive) {
                    training.log(sessionKey, AttemptInput(status: .skipped, skipConfirmedAt: Date()))
                }
                Button("ยกเลิก", role: .cancel) {}
            } message: {
                Text("แผนจะไปต่อที่ Session ถัดไป และบันทึกว่าข้ามโดยคุณยืนยันเอง")
            }
    }
}

struct QuickLogSheet: View {
    @EnvironmentObject private var training: TrainingModel
    @Environment(\.dismiss) private var dismiss
    let sessionKey: String
    @State private var status: AttemptStatus = .completed
    @State private var minutes = ""
    @State private var rpe = 0
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("ผลการฝึก", selection: $status) {
                    Text(AttemptStatus.completed.label).tag(AttemptStatus.completed)
                    Text(AttemptStatus.partial.label).tag(AttemptStatus.partial)
                }.pickerStyle(.segmented)
                Section {
                    TextField("ระยะเวลา (นาที)", text: $minutes).keyboardType(.numberPad)
                    Picker("ความเหนื่อย (RPE)", selection: $rpe) {
                        Text("ไม่ระบุ").tag(0)
                        ForEach(1...10, id: \.self) { Text("\($0)").tag($0) }
                    }
                    TextField("บันทึก", text: $notes, axis: .vertical).lineLimit(3...6)
                } footer: {
                    Text(status == .completed ? "แผนจะไปต่อที่ Session ถัดไป" : "Session นี้จะยังเป็นครั้งต่อไป")
                }
                if let message = training.errorMessage { Text(message).foregroundStyle(.red) }
            }
            .navigationTitle("บันทึกแบบย่อ").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("ยกเลิก") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("บันทึก") {
                        let input = AttemptInput(status: status, duration: Int(minutes), rpe: rpe == 0 ? nil : rpe, notes: notes)
                        if training.log(sessionKey, input) { dismiss() }
                    }.accessibilityIdentifier("quick-log-save")
                }
            }
        }
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(entry.attempt.status.label, systemImage: entry.attempt.status.symbol)
                    .font(.caption.bold()).foregroundStyle(P100Theme.accent)
                Spacer()
                Text(entry.attempt.at.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
            }
            Text(entry.sessionTitle).font(.headline)
            Text(entry.templateName).font(.caption).foregroundStyle(.secondary)
            let stats = [entry.attempt.duration.map { StatItem(label: "เวลา", value: "\($0) นาที") },
                         entry.attempt.rpe.map { StatItem(label: "RPE", value: "\($0)") },
                         entry.attempt.repsDone.map { StatItem(label: "Sprint", value: "\($0) เที่ยว") }].compactMap { $0 }
            if !stats.isEmpty { StatStrip(items: stats) }
            if !entry.attempt.notes.isEmpty { Text(entry.attempt.notes).font(.subheadline) }
            Text(entry.attempt.mode == "live" ? "บันทึกจาก Live Workout · ข้อมูลที่คุณบันทึกเอง" : "บันทึกแบบย่อ · ข้อมูลที่คุณบันทึกเอง")
                .font(.caption2).foregroundStyle(.secondary)
            Divider()
        }.accessibilityElement(children: .combine).accessibilityIdentifier("history-row")
    }
}

struct HistoryScreen: View {
    @EnvironmentObject private var training: TrainingModel
    var body: some View {
        P100Screen {
            if training.history.isEmpty {
                Text("ยังไม่มีประวัติการฝึกในเครื่องนี้").foregroundStyle(.secondary)
            } else {
                ForEach(training.history) { HistoryRow(entry: $0) }
            }
        }.navigationTitle("ประวัติการฝึก").navigationBarTitleDisplayMode(.inline)
    }
}
