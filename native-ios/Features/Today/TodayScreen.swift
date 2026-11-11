import SwiftUI

struct TodayScreen: View {
    var body: some View {
        P100Screen {
            SampleBanner()
            VStack(alignment: .leading, spacing: 8) {
                Text("MOVE AT YOUR PACE").font(.caption.bold()).tracking(1.5).foregroundStyle(P100Theme.accent)
                Text("สวัสดี, เมย์ ☀︎").font(.largeTitle.weight(.bold))
                Text("กลับมาเมื่อพร้อม แล้วไปต่อได้เลย").foregroundStyle(.secondary)
            }
            P100Card {
                Label("ครั้งต่อไปของคุณ · ตัวอย่าง", systemImage: "arrow.forward.circle.fill").font(.subheadline.bold()).foregroundStyle(P100Theme.accent)
                Text("Sprint A + Strength A").font(.title2.bold())
                Text("Block 1 · Session 1\nSprint 4 × 20m · 60–70% · เวทขา").foregroundStyle(.secondary)
                NavigationLink { WorkoutExampleScreen() } label: {
                    Label("ดูตัวอย่าง Session", systemImage: "arrow.right").frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.borderedProminent).accessibilityIdentifier("next-workout-example")
                Text("Session ไม่หมดอายุ แม้หยุดพักหลายวัน").font(.caption).foregroundStyle(.secondary)
            }
            P100Card {
                SectionHeading(title: "เส้นทางของคุณ", subtitle: "100M — The Comeback · ตัวอย่างความคืบหน้า")
                ProgressView(value: 8, total: 60).accessibilityLabel("ตัวอย่าง ฝึกครบ 8 จาก 60 sessions")
                Text("8 / 60 sessions · ตัวอย่าง").font(.subheadline.bold())
                Text("ฝึกครบแล้วจึงไปต่อ ทำบางส่วนยังกลับมาทำครั้งเดิมได้").font(.subheadline).foregroundStyle(.secondary)
            }
            P100Card {
                SectionHeading(title: "Recovery แบบสั้น")
                Text("ดูข้อมูลจริงที่อนุญาตใน Health ส่วนคะแนนและคำแนะนำกำลังพัฒนา").foregroundStyle(.secondary)
                NavigationLink("ดูการเชื่อมต่อ Apple Health") { HealthConnectionScreen() }.frame(minHeight: 44)
            }
            SectionHeading(title: "กิจกรรมล่าสุด · ตัวอย่าง")
            ActivityCard(activity: SampleActivity.examples[0])
            P100Card {
                SectionHeading(title: "Quick Actions")
                Link("เปิดแผนและประวัติเดิมบนเว็บ ↗", destination: P100Theme.dashboardURL).frame(minHeight: 44)
                Text("Native ยังไม่อ่านหรือแก้ไขประวัติเดิม").font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Today")
    }
}

struct WorkoutExampleScreen: View {
    var body: some View {
        P100Screen {
            SampleBanner()
            P100Card {
                SectionHeading(title: "Sprint A + Strength A", subtitle: "ตัวอย่างจาก Session แรกของแผนบนเว็บ")
                Text("Warm-up · 15–20 นาที\nSprint · 4 × 20m ที่ 60–70%\nพักเต็ม · 2–3 นาทีต่อเที่ยว")
                Divider()
                Text("Goblet Squat · 2 × 8\nRomanian Deadlift · 2 × 8\nCalf Raise · 2 × 12\nPlank · 2 × 20–30 วินาที")
                Text("ยังไม่มีการเริ่ม Live Workout หรือบันทึกผลใน Native").font(.caption).foregroundStyle(.secondary)
            }
            Link("ฝึกและบันทึกด้วยเว็บเดิม ↗", destination: P100Theme.dashboardURL).frame(minHeight: 44)
        }.navigationTitle("ตัวอย่าง Session").navigationBarTitleDisplayMode(.inline)
    }
}
