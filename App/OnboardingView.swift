import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: HabitStore
    @State private var name = ""

    var body: some View {
        ZStack {
            QWBackground()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text("Quit With Help")
                    .font(.round(40, .heavy))
                    .foregroundStyle(QW.text)
                Text("Build streaks, and let the people who care about you keep you honest.")
                    .font(.round(18, .medium))
                    .foregroundStyle(QW.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: 10) {
                    Text("What should friends call you?")
                        .font(.round(14, .semibold))
                        .foregroundStyle(QW.muted)
                    TextField("", text: $name, prompt: Text("Your name").foregroundColor(QW.muted))
                        .font(.round(18, .medium))
                        .foregroundStyle(QW.text)
                        .padding(16)
                        .background(QW.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.top, 44)

                Button {
                    store.finishOnboarding(name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "You" : name)
                } label: {
                    Text("Start")
                }
                .buttonStyle(QWButtonStyle())
                .padding(.top, 20)

                Spacer()
            }
            .padding(28)
        }
    }
}
