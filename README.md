# Inkwell — Journaling App

A private, local-first journaling application built with Flutter.

**Platforms:** Windows · macOS · Linux · Android · iOS
**Data:** Stored locally on your device. No cloud, no telemetry.
**Format:** Plain Markdown (`.md`) with YAML frontmatter — fully Obsidian-compatible.

---

## Features

### Core (v1.0)
- **Markdown editor** — switchable between Edit, Preview, and Split-View modes
- **Daily Notes** — auto-generated from template, day navigation
- **Vault** — open any folder as a vault; works alongside Obsidian
- **Full-text search** — SQLite FTS5 index, rebuilt from your files
- **Properties** — Mood, Energy, Sleep, Tags, Location via YAML frontmatter
- **Calendar view** — heatmap of writing activity
- **Auto-save** — 500ms debounce, no data loss
- **Responsive UI** — NavigationBar on mobile, NavigationRail on desktop
- **i18n** — German and English
- **Themes** — Light / Dark / System
- **Font selection** — Inter, Merriweather, JetBrains Mono, Lora, and more

### Roadmap
| Version | Features |
|---------|----------|
| v1.1 | Encrypted vault (AES-256-GCM, Argon2id), Typewriter & Focus mode |
| v1.2 | Speech-to-Text (offline), Quick Capture (global hotkey, floating window) |
| v1.3 | Media embedding, writing prompts, "On This Day" memories, summaries |
| v1.4 | Advanced analytics, heatmap, home screen widgets |
| v1.5 | PDF/EPUB export, import from Day One / Journey / Notion |
| v1.6 | Lifestyle project tracker (weight, fitness, habits, photo timeline) |
| v2.0 | Local AI — sentiment, smart tags, summaries, motivator, note styling |

---

## Data Structure

Your vault is a regular folder. Inkwell stores no data outside of it (except app settings).

```
vault/
  journal/
    2026/
      2026-03-18.md      ← plain Markdown, readable in any editor
  _templates/
    daily.md             ← customize your daily template
  _attachments/          ← images, audio, video (future)
  .inkwell/
    index.db             ← search index (derived, rebuildable)
    settings.json        ← vault-level settings
```

Example entry (`2026-03-18.md`):
```markdown
---
mood: 4
energy: 3
sleep: 7.5
tags:
  - daily
  - work
location: "Berlin"
---

# March 18, 2026

Today was productive...
```

---

## Getting Started

### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install) ≥ 3.x (stable)
- For Linux builds: `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev lld`

### Run
```bash
git clone https://github.com/Fenron-dev/inkwell.git
cd inkwell
flutter pub get
flutter run
```

### Build

```bash
# Linux
flutter build linux --release

# Android
flutter build apk --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

---

## Architecture

- **State management:** [Riverpod](https://riverpod.dev/) (AsyncNotifier, StreamProvider)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) with StatefulShellRoute
- **Database:** [Drift](https://drift.simonbinder.eu/) + SQLite FTS5 (search index only)
- **Markdown:** [flutter_markdown](https://pub.dev/packages/flutter_markdown)
- **i18n:** Flutter's built-in `flutter_localizations` + ARB files
- **Encryption (v1.1):** AES-256-GCM via [cryptography](https://pub.dev/packages/cryptography), Argon2id key derivation

The filesystem is the **source of truth**. The SQLite index is a derived cache that can be rebuilt at any time from the `.md` files.

---

## License

MIT — see [LICENSE](LICENSE)
