import SwiftUI

/// Live Workout: warm-up checklist, sprint reps, strength sets, rest and elapsed timers,
/// pause/resume, RPE, notes and Completed/Partial logging. Every action is saved to the
/// account's local store immediately, so the draft survives app termination.
struct LiveWorkoutScreen: View {
    @EnvironmentObject private var training: TrainingModel
    @Environment(\.dismiss) private var dismiss
    let startKey: String?
    @State private var confirmFinish = false
    @State private var confirmCancel = false
    @State private var result: SessionAttempt?
    @State private var notes = ""
    @State private var didStart = false

    var body: some View {
        Group {
            if let draft = training.live {
                content(draft)
            } else if let result {
                P100Screen { summary(result) }
            } else {
                P100Screen {
                    Text("ยังไม่มี Live Workout").font(.title2.bold())
                    if let message = training.errorMessage { Text(message).foregroundStyle(.red) }
                }
            }
        }
        .navigationTitle("Live Workout").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didStart else { return }
            didStart = true
            if training.live == nil { training.startLive(key: startKey) }
            notes = training.live?.notes ?? ""
        }
    }

    private func act(_ change: (inout TrainingState) throws -> Void) { training.perform(change) }

    @ViewBuilder
    private func content(_ draft: LiveWorkoutDraft) -> some View {
        P100Screen {
            if let startKey, draft.key != startKey {
                StatusBanner(title: "มี Live Workout ค้างอยู่", message: "จบหรือยกเลิก \(draft.title) ก่อนเริ่ม Session อื่น", symbol: "exclamationmark.circle")
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVE WORKOUT · YOUR PACE").font(.caption.bold()).tracking(1.2).foregroundStyle(P100Theme.accent)
                    Text(draft.title).font(P100Type.section).accessibilityIdentifier("live-title")
                }
                Spacer(minLength: 8)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(draft.isPaused ? "หยุดชั่วคราว" : "เวลาซ้อม").font(.caption).foregroundStyle(.secondary)
                        Text(P100Format.clock(draft.elapsed(at: context.date))).font(.title2.bold()).monospacedDigit()
                            .accessibilityIdentifier("live-elapsed")
                    }
                }
            }
            ProgressView(value: Double(draft.unitsDone), total: Double(max(draft.unitsTotal, 1)))
                .accessibilityLabel("สำเร็จ \(draft.unitsDone) จาก \(draft.unitsTotal) ขั้นย่อย")
            Text("สำเร็จ \(draft.unitsDone) จาก \(draft.unitsTotal) ขั้นย่อย · ขั้นตอน \(draft.index + 1)/\(draft.steps.count)")
                .font(.caption).foregroundStyle(.secondary)
            if let step = draft.currentStep { stepCard(step, draft: draft) }
            HStack(spacing: 12) {
                Button { act { try LiveWorkoutEngine.previous(&$0) } } label: { Label("ก่อนหน้า", systemImage: "chevron.left") }
                    .buttonStyle(SecondaryAction()).disabled(draft.index == 0).accessibilityIdentifier("live-previous")
                Button { act { try LiveWorkoutEngine.next(&$0) } } label: { Label("ถัดไป", systemImage: "chevron.right") }
                    .buttonStyle(SecondaryAction()).disabled(draft.index >= draft.steps.count - 1).accessibilityIdentifier("live-next")
            }
            P100Card {
                SectionHeading(title: "รายการที่ต้องฝึก")
                ForEach(Array(draft.steps.enumerated()), id: \.element.id) { index, step in
                    Button { act { try LiveWorkoutEngine.goTo(&$0, index: index) } } label: {
                        HStack {
                            Image(systemName: step.isComplete ? "checkmark.circle.fill" : index == draft.index ? "smallcircle.filled.circle" : "circle")
                                .foregroundStyle(P100Theme.accent)
                            VStack(alignment: .leading) {
                                Text(step.title).font(.subheadline.bold())
                                Text("\(step.done)/\(step.total) · \(step.detail)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }.frame(minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("live-step-\(step.id)")
                }
            }
            finishCard(draft)
        }
        .confirmationDialog(draft.isComplete ? "บันทึกว่าฝึกครบ?" : "บันทึกแบบทำบางส่วน?", isPresented: $confirmFinish, titleVisibility: .visible) {
            Button(draft.isComplete ? "บันทึกว่าฝึกครบ" : "บันทึก Partial") { finish() }
            Button("ฝึกต่อ", role: .cancel) {}
        } message: {
            Text(draft.isComplete ? "แผนจะไปต่อที่ Session ถัดไป" : "Session นี้จะยังเป็นครั้งต่อไป และเก็บส่วนที่ทำแล้วไว้ทำต่อ")
        }
        .confirmationDialog("ยกเลิก Live Workout?", isPresented: $confirmCancel, titleVisibility: .visible) {
            Button("ยกเลิกโดยไม่บันทึก", role: .destructive) { act { LiveWorkoutEngine.cancel(&$0) } }
            Button("ฝึกต่อ", role: .cancel) {}
        } message: {
            Text("ความคืบหน้าของครั้งนี้จะไม่ถูกบันทึก แผนไม่เปลี่ยน")
        }
    }

    private func stepCard(_ step: LiveStep, draft: LiveWorkoutDraft) -> some View {
        P100Card {
            Text(kindLabel(step.kind)).font(.caption.bold()).foregroundStyle(P100Theme.accent)
            Text(step.title).font(.title2.bold())
            Text(step.detail).foregroundStyle(.secondary)
            if let checklist = step.checklist {
                ForEach(checklist) { item in
                    Button { act { try LiveWorkoutEngine.toggleChecklist(&$0, stepId: step.id, itemId: item.id) } } label: {
                        Label(item.title, systemImage: item.done ? "checkmark.square.fill" : "square")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }.buttonStyle(.plain).accessibilityIdentifier("checklist-\(item.id)")
                        .accessibilityAddTraits(item.done ? .isSelected : [])
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(step.done)").font(.system(size: 54, weight: .bold, design: .rounded)).monospacedDigit()
                    Text("/ \(step.total) \(unitLabel(step.kind))").font(.title3).foregroundStyle(.secondary)
                }.accessibilityElement(children: .combine).accessibilityIdentifier("live-count")
                HStack(spacing: 12) {
                    Button { act { try LiveWorkoutEngine.undoUnit(&$0) } } label: { Text("− 1") }
                        .buttonStyle(SecondaryAction()).frame(maxWidth: 110).disabled(step.done == 0)
                        .accessibilityLabel("ลดหนึ่ง").accessibilityIdentifier("live-undo")
                    Button { act { try LiveWorkoutEngine.markUnit(&$0) } } label: {
                        Text(step.isComplete ? "ทำครบแล้ว ✓" : markLabel(step.kind))
                    }.buttonStyle(PrimaryAction()).disabled(step.isComplete).accessibilityIdentifier("live-mark")
                }
            }
            if step.restSeconds > 0 { restTimer(step, draft: draft) }
        }
    }

    private func restTimer(_ step: LiveStep, draft: LiveWorkoutDraft) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = draft.restRemaining(at: context.date)
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        Text("REST TIMER").font(.caption.bold()).foregroundStyle(.secondary)
                        Text(draft.restUntil != nil && remaining == 0 ? "พักครบแล้ว" : P100Format.clock(remaining))
                            .font(.title2.bold()).monospacedDigit().accessibilityIdentifier("live-rest")
                    }
                    Spacer()
                    if draft.restUntil == nil {
                        Button("เริ่มพัก \(step.restSeconds / 60):\(String(format: "%02d", step.restSeconds % 60))") {
                            act { try LiveWorkoutEngine.startRest(&$0, seconds: step.restSeconds) }
                        }.frame(minHeight: 44)
                    } else {
                        Button("ข้ามพัก") { act { try LiveWorkoutEngine.skipRest(&$0) } }.frame(minHeight: 44)
                    }
                }
            }
        }
    }

    private func finishCard(_ draft: LiveWorkoutDraft) -> some View {
        P100Card {
            Text("พร้อมจบการซ้อมแล้วหรือยัง?").font(.headline)
            Text(draft.isComplete ? "ทำครบทุกขั้นตอนแล้ว บันทึกเสร็จตามแผนได้เลย"
                                  : "ถ้ายังไม่ครบ บันทึกแบบ Partial แล้วกลับมาทำ Session นี้ต่อได้")
                .font(.subheadline).foregroundStyle(.secondary)
            Picker("ความเหนื่อย (RPE 1–10)", selection: Binding(
                get: { draft.rpe ?? 0 },
                set: { value in act { try LiveWorkoutEngine.update(&$0, rpe: .some(value == 0 ? nil : value)) } })) {
                Text("RPE ไม่ระบุ").tag(0)
                ForEach(1...10, id: \.self) { Text("RPE \($0)").tag($0) }
            }.frame(minHeight: 44).accessibilityIdentifier("live-rpe")
            TextField("บันทึกความรู้สึก (ไม่บังคับ)", text: $notes, axis: .vertical).lineLimit(2...5)
                .textFieldStyle(.roundedBorder)
                .onChange(of: notes) { _, value in act { try LiveWorkoutEngine.update(&$0, notes: value) } }
            Button(draft.isComplete ? "บันทึกว่าฝึกครบ ✓" : "บันทึกที่ทำไป (Partial)") { confirmFinish = true }
                .buttonStyle(PrimaryAction()).accessibilityIdentifier("live-finish")
            HStack {
                Button(draft.isPaused ? "เดินนาฬิกาต่อ" : "หยุดนาฬิกาชั่วคราว") { act { try LiveWorkoutEngine.togglePause(&$0) } }
                    .frame(minHeight: 44).accessibilityIdentifier("live-pause")
                Spacer()
                Button("ยกเลิก Workout", role: .destructive) { confirmCancel = true }
                    .frame(minHeight: 44).accessibilityIdentifier("live-cancel")
            }
            Text("ปิดแอปได้ งานที่บันทึกไว้จะยังอยู่ในเครื่อง เวลาจับจากนาฬิกาในเครื่อง ไม่ใช่การจับเวลา Sprint อัตโนมัติ")
                .font(.caption).foregroundStyle(.secondary)
            if let message = training.errorMessage { Text(message).foregroundStyle(.red) }
        }
    }

    private func summary(_ attempt: SessionAttempt) -> some View {
        P100Card {
            Label(attempt.status.label, systemImage: attempt.status.symbol).font(.title2.bold()).foregroundStyle(P100Theme.accent)
                .accessibilityIdentifier("live-result")
            Text(attempt.status == .completed ? "บันทึกแล้ว แผนไปต่อที่ Session ถัดไป" : "บันทึกแล้ว Session นี้ยังเป็นครั้งต่อไป")
            StatStrip(items: [StatItem(label: "เวลา", value: "\(attempt.duration ?? 0) นาที"),
                              StatItem(label: "RPE", value: attempt.rpe.map(String.init) ?? "–")])
            Button("เสร็จสิ้น") { dismiss() }.buttonStyle(PrimaryAction()).accessibilityIdentifier("live-done")
        }
    }

    private func finish() {
        var attempt: SessionAttempt?
        if training.perform({ attempt = try LiveWorkoutEngine.finish(&$0) }) { result = attempt }
    }

    private func kindLabel(_ kind: String) -> String {
        switch kind {
        case "sprint": return "วิ่งเร็ว"
        case "strength": return "เวท"
        case "cardio": return "แอโรบิก"
        case "warmup": return "วอร์มอัพ · เช็กลิสต์"
        default: return "ผ่อนลง"
        }
    }

    private func unitLabel(_ kind: String) -> String {
        kind == "sprint" ? "เที่ยว" : kind == "strength" ? "เซต" : "ขั้นตอน"
    }

    private func markLabel(_ kind: String) -> String {
        kind == "sprint" ? "เสร็จอีก 1 เที่ยว ✓" : kind == "strength" ? "เสร็จอีก 1 เซต ✓" : "ทำขั้นตอนนี้แล้ว ✓"
    }
}
