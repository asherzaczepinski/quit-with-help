# quitwithhelp — design system

The single source of truth for how the app looks. Every value lives in
`App/Theme.swift` (the `QW` tokens). Don't hardcode colors, sizes, radii, or
spacing in a screen — pull them from tokens so a restyle is a one-file edit.

## Feel — "cloud rising"
Light, airy, hopeful — a clear sky you're climbing into. Calm and encouraging,
never clinical. White cards float like clouds. Forced light mode.

## Depth policy: SOFT SHADOWS (floating cards)
White cards float over the sky-blue background with one soft, blue-tinted
shadow — like clouds. No hairline borders, no gradient washes on cards. One
policy, everywhere.

## Color — always by role
| Token | Hex | Use |
|---|---|---|
| background | #CADFFF → #F8FBFF | sky gradient (top→bottom) in `QWBackground` |
| `QW.surface` | #FFFFFF | white cards (float with soft shadow) |
| `QW.surface2` | #E9F1FC | inputs, chips, deeper elevation |
| `QW.text` | #17263E | primary text (deep navy) |
| `QW.muted` | #5F7189 | secondary text (WCAG AA on white) |
| `QW.accent` | #2F80ED | THE interactive color: buttons, active tab, streak numbers |
| `QW.danger` | #EF5350 | craving SOS / destructive |
| card shadow | #3E63A8 @ 12% | soft cloud shadow, y+8, blur 16 |

## Type — roles, not numbers (SF Pro Rounded via `Font.round`)
- **largeTitle** 34 heavy — screen hero / streak number
- **title** 24–28 bold — section heroes
- **headline** 17 semibold — card titles, list rows (never below 16 for a row title)
- **body** 15 regular/medium — descriptions (NOT 11–13; that reads like a website)
- **caption** 13 — timestamps, tiny labels only
Weights: regular → medium → semibold → bold → heavy.

## Spacing scale
4 · 8 · 12 · 16 · 20 · 24. Card padding 16–18. Screen margin 20. Gap between
cards 12. Be generous — airy beats cramped.

## Shape
Continuous (squircle) corners. Cards `QW.radius` = 22–24. Inputs/chips 12–16.

## Tap targets
Every interactive element ≥ 44×44pt. Grow the touchable area with padding, not
the visible icon.

## States
Every list/screen needs an empty state (an invitation to act), and ideally
loading + error states. Errors say what happened + the smallest fix.

## Adding a screen
Build from existing tokens + components. Only add to the system if nothing fits —
then add it here and in Theme.swift, never inline in one screen.
