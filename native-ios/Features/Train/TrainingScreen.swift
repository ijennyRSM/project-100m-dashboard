import SwiftUI

struct TrainingScreen: View {
    var body: some View {
        P100Screen {
            SampleBanner()
            SectionHeading(title: "Your next move", subtitle: "Workout ตามจังหวะของคุณ · ไม่ผูกกับวันในสัปดาห์")
            ForEach([SampleProgram.examples[1], SampleProgram.examples[3]]) { program in
                P100Card {
                    Label(program.id == "run5k" ? "Running" : "Strength", systemImage: program.symbol).font(P100Type.hero)
                    Text(program.id == "run5k" ? "เริ่มเบา ๆ แล้วค่อยไปไกลขึ้น" : "สร้างพื้นฐานให้ทุกการเคลื่อนไหว").foregroundStyle(.secondary)
                    NavigationLink { ProgramExampleScreen(program: program) } label: {
                        Label("ดูตัวอย่าง Workout", systemImage: "arrow.right")
                    }.buttonStyle(PrimaryAction())
                }
            }
            NavigationLink { MapsScreen() } label: {
                HStack {
                    Label("Maps · สำรวจหน้าตาเส้นทาง", systemImage: "map").font(.headline)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }.padding(16).frame(minHeight: 48).background(P100Theme.surface, in: RoundedRectangle(cornerRadius: 16))
            }.buttonStyle(.plain).accessibilityIdentifier("open-maps")
            SectionHeading(title: "Training library", subtitle: "ห้าโปรแกรม · ตัวอย่าง ยังไม่เปิดลงทะเบียน")
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
        }.navigationTitle("Train").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    IconLink(title: "Maps", symbol: "map") { MapsScreen() }
                }
            }
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
