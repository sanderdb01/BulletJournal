# HarborDot — UX & Product Experience Report
*(Option C deliverables: Markdown + PDF companion)*

**Owner:** David Sanders  

**Reviewer/Partner:** ChatGPT (GPT-5 Thinking)  

**Date:** 2025-10-17

---

## 1) Product Summary (as of v1 functional wireframe)
HarborDot is a calm, notebook‑feel task app designed for ADHD users (and anyone who wants friction‑light progress). Core primitives are **Tasks**, **Calendar**, and **Notes** (including a general Markdown‑first notes section). Tasks advance through **Normal → In Progress → Complete → Not Complete** with color tags, repeats, reminders, and iCloud sync across iPhone, iPad, and Mac.

**Repo signals observed:** multiple Apple platform targets (iOS, macOS, watchOS widgets) and app icon assets, consistent with cross‑device scope.

---

## 2) Current Journey Map (as implemented conceptually)
1. **Open app → Today** (default landing)  

2. **Capture task** (+ button or inline)  

3. **Advance state** (tap/gesture cycles Normal → In Progress → Complete → Not Complete)  

4. **Calendar glance** (dot density indicates days with tasks; tap a day to preview)  

5. **Notes** (per‑day or per‑task; General Notes supports Markdown + Preview)  

6. **Search** across tasks and notes  

7. **Sync** via iCloud on iPhone/iPad/Mac

---

## 3) UX Opportunities (high‑impact, low complexity)
### A. Completion Dopamine Loop
- **Micro‑animation:** 140–180ms scale‑and‑settle on checkbox/dot.  

- **Ink stroke option:** cross‑out with a 180–220ms eased pen stroke; fades to 75% opacity.  

- **Haptic:** `.impact(.soft)` on Complete; `.selectionChanged()` on state step.  

- **Confetti (optional, off by default):** 6–8 particles, 300–400ms, low contrast.

### B. Calendar Dots (clarity & density)
- **Dot hierarchy:** size = task count bucket; opacity = completion ratio.  

- **Selected day reveal:** 180ms slide‑in task list with subtle shadow (“page” affordance).

### C. Capture Speed
- **Global quick capture:** deep link / share extension to append to Today.  

- **One‑tap input focus:** opening places cursor in the first empty row.

### D. Layout Rhythm
- **Spacing scale:** 4/8/12/16/24/32pt; default stack gaps 12–16pt.  

- **Card radius:** 14–16pt; **hit targets:** 44pt min height.  

- **Typography:** SF Pro Text; sizes 15/17/22 (body/title/large title).

### E. Markdown Notes Delight
- **Preview toggle animation:** 160ms cross‑fade + slide‑up 8pt.  

- **Code blocks & checklists:** maintain “paper” look with monospaced inset.

---

## 4) Color Systems (ADHD‑friendly)

> Goal: calm base, sparing accent. Dark & light pairs included.

### Palette 1 — *Harbor Calm*
- Base: **Paper** `#FAFAF8`, **Ink** `#1F2937`  

- Accent: **Coral** `#FF6B6B` (Complete pulse), **Teal** `#2DD4BF` (In Progress)  

- Tags (pastels): `#A7F3D0`, `#BFDBFE`, `#FDE68A`, `#FBCFE8`

### Palette 2 — *Ink & Dot*
- Base: **Charcoal** `#111827`, **Ice** `#F3F4F6`  

- Accent: **Cyan** `#22D3EE`, **Lime** `#84CC16`  

- Tags (muted): `#60A5FA`, `#F472B6`, `#F59E0B`, `#34D399`

### Palette 3 — *Dopamine Pop (subtle)*
- Base: **Warm Gray** `#F5F5F4`, **Graphite** `#0F172A`  

- Accent (momentary): **Electric Peach** `#FF8A5B` (completion glow)

**Usage rules:**  

- 90/10 rule: 90% neutral, 10% accent.  

- Reserve bright chroma for **motion moments** (completion, selection).

---

## 5) Motion Specs (starter tokens)

| Token | Duration | Curve | Notes |
|---|---:|---|---|
| `taskComplete.pop` | 160–180ms | spring(0.7, 0.9) | scale 1→1.06→1 |
| `taskStrike.stroke` | 200ms | easeInOut | line grows L→R, fade to 75% |
| `stateChange.nudge` | 120ms | easeOut | subtle y‑nudge 2–3pt |
| `calendar.reveal` | 180ms | easeOut | slide‑in + shadow 8pt |
| `markdown.toggle` | 160ms | easeInOut | cross‑fade + slide‑up 8pt |

**Haptics:** soft impact on complete; selection on intermediate states.

---

## 6) Information Architecture (recommended labels)
- **Today** (default)  

- **Calendar**  

- **Notes** (General Notes at top; search bar present across screens)  

- **Search** (global, recent queries, filters: tag, state, date)

**Task states (copy):** Normal • In Progress • Complete • Not Complete  

**Empty states:** “Type to capture…” with one example row.

---

## 7) Accessibility & ADHD‑aware Defaults
- Dynamic Type support (AA+); minimum body size 15pt.  

- Focus retention: when a modal closes, return cursor to previous input.  

- Undo everywhere (two‑finger).  

- Motion‑sensitive: reduce motion setting disables pop/slide; keep haptics.  

- Color‑alone never conveys meaning (use shape/label).

---

## 8) Quick Wins (you can ship these fast)
1) Add haptic + 160ms pop on Complete.  

2) Increase tap targets to 44pt and card radius to 14–16pt.  

3) Calendar dot sizing by bucket (1, 2–3, 4–6, 7+).  

4) Markdown preview animated toggle.  

5) Consistent spacing token scale (8/12/16/24).

---

## 9) Longer‑Horizon Enhancements (still calm)
- Saved filters (e.g., “Blue + In Progress + This Week”).  

- Templates for daily resets or meeting notes.  

- `[[Links]]` between notes and tasks.  

- Focus Dock pill for current task.  

- Optional gentle streaks for Daily Reset template.

---

## 10) Naming & Branding in Code
- Adopt **HarborDot** everywhere (targets, bundle id prefixes, folder names).  

- File naming examples: `HarborTask.swift`, `HarborCalendarView.swift`, `HarborNotesView.swift`, `HarborSync.swift`.

---

## 11) Implementation Hints (SwiftUI + SwiftData)
- Centralize **TaskState** and **ColorTag** enums for reuse.  

- Use a **ViewModifier** for completion animations/haptics to ensure consistency.  

- Consider a **DesignTokens.swift** for spacing, radius, durations, and colors.

---

## 12) Success Metrics
- Time to first captured task (<4s).  

- % tasks reaching Complete per day.  

- 7‑day return rate.  

- “Not Complete” trend (aim to decline).  

- Delight pulse (1‑tap) after 3rd completion.

---

## 13) Appendix
### Suggested SwiftUI tokens (example)
```swift
enum Motion {
  static let complete = 0.17
  static let strike = 0.20
  static let reveal = 0.18
  static let toggle = 0.16
}

enum Radius {
  static let card: CGFloat = 16
}

enum Spacing {
  static let s: CGFloat = 8
  static let m: CGFloat = 12
  static let l: CGFloat = 16
  static let xl: CGFloat = 24
}
```
