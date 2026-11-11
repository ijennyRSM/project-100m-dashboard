import SwiftUI

struct FeedScreen: View {
    var body: some View {
        P100Screen {
            SampleBanner()
            SectionHeading(title: "ก้าวเล็ก ๆ ที่แบ่งปันได้", subtitle: "กิจกรรมจากชุมชน · ตัวอย่างการออกแบบ")
            ForEach(SampleActivity.examples) { ActivityCard(activity: $0) }
            StatusBanner(title: "คุณเลือกเองว่าจะแชร์อะไร", message: "Workout ใหม่จะเป็นส่วนตัว การสร้างโพสต์และปฏิสัมพันธ์จะเปิดใช้หลังระบบบัญชีและความเป็นส่วนตัวพร้อม", symbol: "lock.shield")
        }.navigationTitle("Feed")
    }
}
