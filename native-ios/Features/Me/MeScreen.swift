import SwiftUI
import Charts

struct MeScreen: View {
    @EnvironmentObject private var account: AccountModel
    @EnvironmentObject private var training: TrainingModel
    @State private var section = "Progress"
    @State private var confirmSignOut = false
    @State private var confirmImport = false

    private var attempts: [SessionAttempt] { training.history.map(\.attempt) }

    var body: some View {
        P100Screen(horizontalPadding: 0, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                identity
                actions
                if account.phase == .signedIn && training.guestImportAvailable { guestImport }
            }.padding(.horizontal, P100Space.page)
            UnderlineTabs(labels: ["Progress", "Activities", "Gallery", "More"],
                          symbols: ["chart.bar.doc.horizontal", "waveform.path.ecg", "square.grid.3x3", "line.3.horizontal"],
                          selection: $section, id: "profile-section")
            switch section {
            case "Activities": activities
            case "Gallery":
                VStack(alignment: .leading, spacing: 12) {
                    SampleBanner()
                    RouteIllustration().frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 16))
                    Text("ภาพประกอบต้นฉบับเท่านั้น ยังไม่มีรูปส่วนตัวหรือการอัปโหลดภาพ").foregroundStyle(.secondary)
                }.padding(.horizontal, P100Space.page)
            case "More": more
            default: progress
            }
        }.navigationTitle("Me").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    IconLink(title: "ความเป็นส่วนตัวและการแชร์", symbol: "gearshape") { PrivacyScreen() }
                }
            }
            .confirmationDialog("คัดลอกข้อมูล Guest เข้าบัญชีนี้?", isPresented: $confirmImport, titleVisibility: .visible) {
                Button("คัดลอก") { training.importGuestData() }
                Button("ยกเลิก", role: .cancel) {}
            } message: {
                Text("แผน ประวัติ และ Live Workout ที่ค้างอยู่ในโหมด Guest จะถูกคัดลอกเข้าบัญชี \(account.user?.email ?? "")")
            }
            .confirmationDialog("ออกจากระบบ?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("ออกจากระบบ (เก็บข้อมูลฝึกในเครื่องไว้)") { Task { await signOut(removeData: false) } }
                Button("ออกจากระบบและลบข้อมูลฝึกของบัญชีนี้ในเครื่อง", role: .destructive) { Task { await signOut(removeData: true) } }
                Button("ยกเลิก", role: .cancel) {}
            } message: {
                Text("Session ใน Keychain จะถูกลบ ข้อมูลฝึกของบัญชีนี้จะถูกซ่อนจนกว่าจะเข้าสู่ระบบอีกครั้ง เว้นแต่เลือกลบ")
            }
    }

    // MARK: Header

    private var identity: some View {
        HStack(alignment: .center, spacing: 16) {
            ProfileAvatar(initial: String(account.displayName.prefix(1)).uppercased(), size: 76)
            VStack(alignment: .leading, spacing: 4) {
                if account.phase == .signedIn {
                    Text(account.displayName).font(.title.bold()).accessibilityIdentifier("screen-me")
                } else {
                    Text(account.phase == .restoring ? "กำลังตรวจสอบบัญชี…" : "ยังไม่ได้เข้าสู่ระบบ").font(.title2.bold())
                        .accessibilityIdentifier("screen-me")
                }
                Text("\(training.history.count) บันทึก").font(.title3)
                Text(account.phase == .signedIn
                     ? (account.isOffline ? "บัญชี PROJECT 100M · ออฟไลน์" : account.user?.email ?? "บัญชี PROJECT 100M")
                     : "โหมด Guest บนเครื่องนี้")
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            if account.phase == .signedIn {
                NavigationLink { SignInScreen() } label: { Text("บัญชี") }
                    .buttonStyle(OutlineAction()).accessibilityIdentifier("me-account")
            } else {
                NavigationLink { SignInScreen() } label: { Text("เข้าสู่ระบบ") }
                    .buttonStyle(OutlineAction(accent: true)).accessibilityIdentifier("me-sign-in")
            }
            NavigationLink { PrivacyScreen() } label: { Text("ความเป็นส่วนตัว") }
                .buttonStyle(OutlineAction())
        }
    }

    private var guestImport: some View {
        P100Card {
            Label("พบข้อมูลฝึกโหมด Guest ในเครื่องนี้", systemImage: "tray.and.arrow.down").font(.headline)
            Text("บัญชีนี้ยังไม่มีแผนในเครื่อง คัดลอกแผนและประวัติจากโหมด Guest เข้าบัญชีนี้ได้ ข้อมูล Guest เดิมยังอยู่ และไม่มีการส่งขึ้นคลาวด์")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("คัดลอกเข้าบัญชีนี้…") { confirmImport = true }.buttonStyle(SecondaryAction())
                .accessibilityIdentifier("import-guest")
        }
    }

    // MARK: Progress (real recorded attempts only)

    private var progress: some View {
        let weeks = TrainingStats.weekly(attempts, count: 12)
        let current = weeks.last
        let streak = TrainingStats.weekStreak(attempts)
        return VStack(alignment: .leading, spacing: 16) {
            P100Card {
                Text("สัปดาห์นี้").font(.title2.bold())
                StatStrip(items: [StatItem(label: "ครั้ง", value: "\(current?.sessions ?? 0)"),
                                  StatItem(label: "เวลา", value: "\(current?.minutes ?? 0) นาที"),
                                  StatItem(label: "Live Workout", value: "\(attempts.filter { $0.mode == "live" }.count)")])
                Text("12 สัปดาห์ที่ผ่านมา · นาทีที่บันทึก").font(.subheadline).foregroundStyle(.secondary)
                WeeklyChart(weeks: weeks)
            }
            P100Card {
                HStack {
                    Text("Streak").font(.title3.bold())
                    Spacer()
                    Text("สัปดาห์ติดต่อกัน").font(.subheadline).foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "flame.fill").font(.largeTitle).foregroundStyle(P100Theme.accent).accessibilityHidden(true)
                    Text("\(streak)").font(.system(size: 44, weight: .bold, design: .rounded)).monospacedDigit()
                    Text("สัปดาห์").font(.title3).foregroundStyle(.secondary)
                }.accessibilityElement(children: .combine)
                HStack(spacing: 8) {
                    ForEach(weeks.suffix(8)) { week in
                        Circle().fill(week.sessions > 0 ? P100Theme.accent : Color.primary.opacity(0.15)).frame(width: 14, height: 14)
                    }
                }.accessibilityHidden(true)
                Text("นับสัปดาห์ที่มีการฝึกครบหรือบางส่วนอย่างน้อยหนึ่งครั้ง ไม่ใช่เงื่อนไขของแผน").font(.caption).foregroundStyle(.secondary)
            }
            P100Card {
                SectionHeading(title: "แผนปัจจุบัน", subtitle: training.activeTemplate?.name ?? "ยังไม่ได้เลือกแผน")
                if let overview = training.overview {
                    ProgressView(value: Double(overview.completed + overview.skipped), total: Double(max(overview.total, 1)))
                    Text("\(overview.percent)% · ฝึกครบ \(overview.completed) · ข้าม \(overview.skipped) · ทั้งหมด \(overview.total)")
                        .font(.subheadline.bold())
                } else {
                    NavigationLink("เลือกแผนฝึก") { TrainingLibraryScreen() }.frame(minHeight: 44)
                }
            }
        }.padding(.horizontal, P100Space.page)
    }

    // MARK: Activities

    @ViewBuilder private var activities: some View {
        if training.history.isEmpty {
            Text("ยังไม่มีกิจกรรมที่บันทึกในเครื่องนี้").foregroundStyle(.secondary)
                .padding(.horizontal, P100Space.page).accessibilityIdentifier("profile-activities-empty")
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(training.history.prefix(20)) { entry in
                    ActivityPost(
                        header: ActivityHeader(initial: String(account.displayName.prefix(1)).uppercased(), name: account.displayName,
                                               meta: entry.attempt.at.formatted(date: .abbreviated, time: .shortened),
                                               context: "\(entry.templateName) · \(entry.attempt.status.label)",
                                               symbol: entry.attempt.status.symbol),
                        title: entry.sessionTitle, description: entry.attempt.notes,
                        stats: Self.stats(entry.attempt),
                        footnote: entry.attempt.mode == "live" ? "Live Workout · ส่วนตัว" : "บันทึกแบบย่อ · ส่วนตัว")
                    SectionBand()
                }
            }
        }
    }

    static func stats(_ attempt: SessionAttempt) -> [StatItem] {
        var items: [StatItem] = []
        if let minutes = attempt.duration { items.append(StatItem(label: "เวลา", value: "\(minutes) นาที")) }
        if let rpe = attempt.rpe { items.append(StatItem(label: "RPE", value: "\(rpe)")) }
        if let reps = attempt.repsDone { items.append(StatItem(label: "Sprint", value: "\(reps) เที่ยว")) }
        return items
    }

    // MARK: More

    private var more: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink { HealthConnectionScreen() } label: {
                ListRowLabel(symbol: "applewatch", title: "Apple Health และอุปกรณ์", value: "อ่านในเครื่องเท่านั้น")
            }.buttonStyle(.plain).accessibilityLabel("Apple Health และอุปกรณ์")
            Divider().padding(.leading, 64)
            NavigationLink { HistoryScreen() } label: {
                ListRowLabel(symbol: "list.bullet.rectangle", title: "ประวัติการฝึก", value: "\(training.history.count) รายการ")
            }.buttonStyle(.plain)
            Divider().padding(.leading, 64)
            NavigationLink { PrivacyScreen() } label: {
                ListRowLabel(symbol: "lock.shield", title: "ความเป็นส่วนตัวและการแชร์", value: "ส่วนตัวเป็นค่าเริ่มต้น")
            }.buttonStyle(.plain)
            Divider().padding(.leading, 64)
            if account.phase == .signedIn {
                Button { confirmSignOut = true } label: {
                    ListRowLabel(symbol: "rectangle.portrait.and.arrow.right", title: "ออกจากระบบ", value: account.user?.email)
                }.buttonStyle(.plain).foregroundStyle(.red).accessibilityIdentifier("me-sign-out")
            } else {
                NavigationLink { SignInScreen() } label: {
                    ListRowLabel(symbol: "person.badge.key", title: "เข้าสู่ระบบ", value: "บัญชีเดียวกับเว็บไซต์")
                }.buttonStyle(.plain)
            }
            SectionBand().padding(.vertical, 12)
            Link(destination: P100Theme.dashboardURL) {
                ListRowLabel(symbol: "safari", title: "เปิดประวัติเดิมบนเว็บ", value: "ยังไม่ซิงก์กับแอป")
            }.buttonStyle(.plain)
        }
    }

    private func signOut(removeData: Bool) async {
        let scope = account.scope
        await account.signOut()
        if removeData { training.deleteLocalData(for: scope) }
    }
}

/// 12-week line chart of recorded minutes (zeros when nothing was logged).
struct WeeklyChart: View {
    let weeks: [WeekSummary]
    var body: some View {
        Chart(weeks) { week in
            AreaMark(x: .value("สัปดาห์", week.weekStart), y: .value("นาที", week.minutes))
                .foregroundStyle(LinearGradient(colors: [P100Theme.accent.opacity(0.35), P100Theme.accent.opacity(0.02)],
                                                startPoint: .top, endPoint: .bottom))
            LineMark(x: .value("สัปดาห์", week.weekStart), y: .value("นาที", week.minutes))
                .foregroundStyle(P100Theme.accent).lineStyle(StrokeStyle(lineWidth: 2.5))
            PointMark(x: .value("สัปดาห์", week.weekStart), y: .value("นาที", week.minutes))
                .foregroundStyle(P100Theme.accent).symbolSize(28)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated)) }
        }
        .chartYAxis { AxisMarks(position: .trailing) }
        .frame(height: 170)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("กราฟเวลาฝึก 12 สัปดาห์ สัปดาห์นี้ \(weeks.last?.minutes ?? 0) นาที")
        .accessibilityIdentifier("profile-progress")
    }
}
