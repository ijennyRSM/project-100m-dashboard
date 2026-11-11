import SwiftUI

struct TrainingScreen: View {
    var body: some View {
        P100Screen {
            SampleBanner()
            SectionHeading(title: "เลือกเส้นทางที่เหมาะกับคุณ", subtitle: "ไม่ผูกกับวันในสัปดาห์ · ตัวอย่างคลังโปรแกรม")
            ForEach(SampleProgram.examples) { program in
                NavigationLink { ProgramExampleScreen(program: program) } label: {
                    P100Card {
                        Label(program.name, systemImage: program.symbol).font(.headline)
                        Text(program.summary).font(.subheadline).foregroundStyle(.secondary)
                        Label("ดูตัวอย่าง", systemImage: "chevron.right").font(.caption)
                    }
                }.buttonStyle(.plain).accessibilityIdentifier("program-\(program.id)")
            }
            Link("เปิดแผนจริงบนเว็บ ↗", destination: P100Theme.dashboardURL).frame(minHeight: 44)
        }.navigationTitle("Train")
    }
}

struct ProgramExampleScreen: View {
    let program: SampleProgram
    var body: some View {
        P100Screen {
            SampleBanner()
            P100Card {
                Label(program.name, systemImage: program.symbol).font(.title2.bold())
                Text(program.summary)
                Text("ฝึกครบ → Session ถัดไป\nทำบางส่วน → Session เดิม\nข้าม → ต้องยืนยันก่อนเสมอ").font(.subheadline).foregroundStyle(.secondary)
                Text("ยังไม่เปิดลงทะเบียนหรือบันทึกผลใน Native").font(.caption)
            }
        }.navigationTitle("ตัวอย่างโปรแกรม").navigationBarTitleDisplayMode(.inline)
    }
}
