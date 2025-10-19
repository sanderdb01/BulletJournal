# 🌊 HarborDot

> “Dock your day.” A calm, tactile task app designed for ADHD brains — and anyone who craves the dopamine of done.

---

## 🩶 Overview

**HarborDot** is a minimalist, notebook-feel task manager for iPhone, iPad, and Mac.\
It’s built for people who love the satisfaction of checking things off — without the noise, pressure, or clutter of most productivity apps.

All your data syncs quietly through iCloud, so your notes and tasks follow you everywhere.\
Paper gives you dopamine — HarborDot keeps it in your pocket.

---

| Category                    | Description                                                                                   |
| --------------------------- | --------------------------------------------------------------------------------------------- |
| 🗓️ **Daily Task Tracking** | Cycle through `Normal → In Progress → Complete → Not Complete` with a single tap.             |
| 🌈 **Color Tags**           | Assign visual context to tasks — projects, moods, or focus zones.                             |
| 🔁 **Repeats & Reminders**  | Schedule recurring tasks and gentle notifications.                                            |
| 📔 **Notes Everywhere**     | Add notes to days or tasks; plus a Markdown-friendly general notes section with live preview. |
| 🗕️ **Calendar View**       | See your month at a glance — color dots mark task days.                                       |
| 🔍 **Global Search**        | Find anything instantly across tasks and notes.                                               |
| ☁️ **iCloud Sync**          | Seamless data sync across iPhone, iPad, and Mac.                                              |

---

> “I built HarborDot because I have ADHD — and notebooks were the only thing that ever worked for me.”

Every tap, color, and animation is designed to deliver a *gentle dopamine hit* without overstimulation.\
No streaks, no gamified pressure — just quiet progress.

**Principles**

- 🪘 Calm by default — low-contrast, uncluttered design
- ⚡ Dopamine-friendly — tactile satisfaction for every task state
- 📝 Fast capture — frictionless from thought → list
- 🎯 Low pressure — never punishes missed days
- ♿ Accessible — dynamic type, focus retention, reduced motion aware

---

Built entirely with **SwiftUI + SwiftData**, targeting **iOS 17+ / macOS 14+**.

**Core Layers**

- `HarborTask.swift` — Task model (title, state, tag, repeat, reminder)
- `HarborCalendarView.swift` — Month view + dot markers
- `HarborNotesView.swift` — Notes and Markdown preview
- `HarborSync.swift` — iCloud sync logic
- `DesignTokens.swift` — Color, spacing, radius, and motion constants

---

| Palette             | Description                                                         |
| ------------------- | ------------------------------------------------------------------- |
| **🌤️ Harbor Calm** | Paper whites, ink grays, coral and teal accents — serene and clean. |
| **🌑 Ink & Dot**    | Deep charcoal base, icy highlights, muted pastels.                  |
| **⚡ Dopamine Pop**  | Warm grays and electric peach accent for the “completion glow.”     |

Each palette is designed for ADHD-friendly contrast and emotional balance — calm neutrals, occasional accent highlights, and consistent feedback loops.

---

| State            | Visual                    | Description      |
| ---------------- | ------------------------- | ---------------- |
| **Normal**       | Neutral dot               | Unstarted task   |
| **In Progress**  | Teal pulse                | Actively working |
| **Complete**     | Coral check + soft haptic | Dopamine moment  |
| **Not Complete** | Dimmed + cross-out        | Task revisited   |

---

| Phase    | Focus                                         |
| -------- | --------------------------------------------- |
| **v1.0** | Core task flow, notes, Markdown, iCloud sync  |
| **v1.1** | Dopamine animations, haptics, Focus Dock pill |
| **v1.2** | Saved filters, templates, cross-note links    |
| **v1.3** | Shared lists & “Household Mode”               |

---

## 🧠 Philosophy

HarborDot isn’t about productivity — it’s about *peace*.\
It’s the digital version of your favorite notebook: no guilt, no clutter, no streak anxiety.\
You open it, jot something down, and leave with a little hit of clarity.

---

## 🚀 Installation (Developer)

```bash
git clone https://github.com/sanderdb01/BulletJournal.git
cd BulletJournal
open HarborDot.xcodeproj
```

Requires **Xcode 15+** and **iOS 17 / macOS 14 SDK**.\
Universal target for iPhone, iPad, and Mac.

---

## 💬 Contributing

Ideas welcome! Open a Discussion or Issue to share your feedback.\
HarborDot’s mission is to make task tracking *feel good* — your input helps shape that feeling.

---

## 🩩 License

MIT License © 2025 David Sanders

