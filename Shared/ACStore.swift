import Foundation
import SwiftUI

// ── Widget-safe helpers (compiled into BOTH the app and the widget). ──
// The live, Supabase-backed store lives in App/HabitStore.swift (app only).

// Shared UserDefaults (app group if available, else standard so it still builds/runs).
func acDefaults() -> UserDefaults { UserDefaults(suiteName: kAppGroup) ?? .standard }

private let kSnapshot = "ac_widget_snapshot"

/// Reads/writes the tiny snapshot the widget shows.
enum ACSnapshotIO {
    static func read() -> WidgetSnapshot {
        guard let d = acDefaults().data(forKey: kSnapshot),
              let s = try? JSONDecoder().decode(WidgetSnapshot.self, from: d) else { return WidgetSnapshot() }
        return s
    }
    static func write(_ s: WidgetSnapshot) {
        if let d = try? JSONEncoder().encode(s) { acDefaults().set(d, forKey: kSnapshot) }
    }
}

// hex -> Color helper (used across app + widget)
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces); if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF)/255, g = Double((v >> 8) & 0xFF)/255, b = Double(v & 0xFF)/255
        self = Color(red: r, green: g, blue: b)
    }
}
