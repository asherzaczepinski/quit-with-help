import SwiftUI
import UIKit

// Dismiss the keyboard (tap outside a field).
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// "Cloud rising" — light sky-blue, white cards floating like clouds.
enum QW {
    static let bg       = Color(hex: "E7F1FF")
    static let surface  = Color(hex: "FFFFFF")
    static let surface2 = Color(hex: "E9F1FC")
    static let text     = Color(hex: "17263E")
    static let muted    = Color(hex: "5F7189")
    static let accent   = Color(hex: "2F80ED")
    static let danger   = Color(hex: "EF5350")
    static let radius: CGFloat = 24
}

extension Font {
    static func round(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// Sky gradient with soft clouds rising from the bottom.
struct QWBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: "CADFFF"), Color(hex: "E4EFFF"), Color(hex: "F8FBFF")],
                       startPoint: .top, endPoint: .bottom)
            .overlay(alignment: .bottom) {
                Ellipse()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 680, height: 340)
                    .blur(radius: 100)
                    .offset(y: 150)
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
    }
}

extension View {
    // White card floating with a soft blue-tinted shadow (cloud).
    func qwCard(_ pad: CGFloat = 18) -> some View {
        self.padding(pad)
            .background(QW.surface, in: RoundedRectangle(cornerRadius: QW.radius, style: .continuous))
            .shadow(color: Color(hex: "3E63A8").opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

struct QWButtonStyle: ButtonStyle {
    var bg: Color = QW.accent
    var fg: Color = .white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.round(17, .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(fg)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}
