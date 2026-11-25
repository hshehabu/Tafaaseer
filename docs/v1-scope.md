# Tafaseer v1 scope

These decisions were saved on 24 Nov 2026 from the team's [scope checklist](https://claude.ai/artifact/WVibj5J2Q8DEb9vdXapuoo). The codes (A1, E3 and so on) refer to items in that checklist.

## What we are building

A free, Arabic-only Android app for the general reader. While reading the Quran, the user long-presses an ayah to read a short, clear explanation, and can switch to one of five classical tafsirs for more depth. Everything works offline from the first launch. There are no accounts and no ads.

## Product

| | Decision |
|---|---|
| Main user (A1) | General reader |
| Core job (A2) | Quick look-up while reading |
| Interface language (A3) | Arabic only |
| Tafsirs (A4) | **al-Muyassar** (default) plus Ibn Kathir, al-Sa'di, al-Tabari, al-Qurtubi, al-Baghawi |
| Money (B1) | Free, no ads |
| Platform (B2) | Android first |
| Source code (B3) | Open source |
| Accounts (B4) | None. All data stays on the device |
| Analytics (B5) | Crash reports only |
| Success measure (B6) | Store rating |

## Quran reading screen

- Verse list with one ayah per row (D1), in Uthmani Hafs text (C5) using the KFGQPC Hafs font (F4, confirmed 24 Nov 2026).
- v1 features:
  - Surah index (D2)
  - Juz and hizb navigation (D3)
  - Jump to ayah (D4)
  - Resume last position (D5)
  - Font size (D6)
  - Light, dark and sepia themes (D7)
  - Bookmarks (D8)

## Tafsir panel

- **Opening:** long-press an ayah to open a bottom sheet (E1, E2) that drags from half to full screen.
- **Switching tafsirs:** the top of the sheet shows a row of pills with the tafsir names, and the user taps one to switch. Nothing more (E3 note).
- **Default tab:** al-Muyassar is always selected when the sheet opens (E4 note).
- **Header:** the sheet header shows the ayah reference, for example "البقرة ٢٥٥", and the range when the commentary is shared, for example "٢:١–٥". It also holds three actions:
  - **Copy:** copies the ayah and the open tafsir text, with its reference.
  - **Share:** shares the same text with the system share sheet.
  - **Bookmark:** saves the ayah. This is the only way to bookmark (D8), because long-press opens the tafsir.
- v1 features:
  - Next and previous ayah without closing the sheet (E5)
  - Length badge on each pill (E6)
  - Remember scroll position in each entry (E7)
  - Copy and share with the reference (E8), from the sheet header
  - Find within the open entry (E9)
  - Tafsir font and line spacing settings (E10)
  - Side panel on tablets (E11)

## Tafsir text

- **Clean-up (C1):**
  - Remove editor footnotes from the main text and show them as small tap-to-show markers (C2).
  - Fix paragraph breaks.
  - Add a toggle that hides narrator chains (isnad).
- **Diacritics (C3):** a toggle, and the user picks the default.
- **Commentary covering several ayahs (C4):** show "Commentary for 2:1–5" and highlight those ayahs in the reader.
- **Data source:** QUL (qul.tarteel.ai), using these IDs: al-Muyassar 38, Ibn Kathir 22, al-Sa'di 24, al-Tabari 37, al-Qurtubi 23, al-Baghawi 27. Use Sa'di ID 24, not 308.
- **Delivery:** all six tafsirs ship inside the app, about 35 MB (C6). Content changes only arrive with app updates (C7).

## Technical

| | Decision |
|---|---|
| Framework (F1) | Flutter |
| Storage (F2) | SQLite, with each ayah's tafsir text compressed separately |
| Data-cleaning script (F3) | Python |
| Minimum OS (F5) | Android 7+ (iOS 13+ when iOS comes) |
| Accessibility (F6) | Screen-reader labels, right-to-left layout, system text size |
| Data check (F7) | Every one of the 6,236 ayahs resolves to text in all six tafsirs |
| Rendering tests (F8) | Very long entries (the longest is al-Qurtubi on 4:43, about 108,000 characters) |

The app must also ship a credits page (B7) and an Arabic app name and icon (B8).

## Implementation notes

These come from reviewing [quran-offline-mobile](https://github.com/hndrwn-dk/quran-offline-mobile), an open-source Flutter app that reads QUL data in production.

- **Quran text and font:**
  - Show the KFGQPC Hafs text (`ayahs.text`) exactly as stored, with the KFGQPC Hafs font. Never mix in Quran text from another source.
  - Take the bismillah header from ayah 1:1 in our database, not from a hardcoded string.
  - Add a test that no ayah renders a dotted circle (U+25CC).
- **Shipping the database:**
  - Bundle `tafaseer.db` as an asset. On first launch, copy it to app storage atomically, so an interrupted copy can't leave a half-written file.
  - Open it read-only and check that it opens. Copy it again if it's corrupt.
  - Copy again whenever the app's `bundleVersion` constant changes.
  - Expect a one-time 45 MB copy, about 1–2 seconds.
- **Long entries:** build tafsir paragraphs lazily in a scrolling list. A single column of every paragraph would stall on al-Qurtubi's longest entries, about 108,000 characters.
- **Release data:** before release, download the six official QUL SQLite exports into `pipeline/input/qul/` and rebuild, instead of using the GitHub mirror. On that first build, check how the pipeline handles QUL's HTML, especially `class="qpc-hafs"` blocks.

## Later (not v1)

- Personal notes on ayahs (D9)
- Mushaf page view (D10)
- Contents list for long entries (E12)
- Compare two tafsirs side by side (E13)
- Search across all tafsirs (E14)

## Not doing

- Audio (D11)
- Translations (D12)
- More tafsirs (G1)
- Accounts and social features (G2)
- Prayer times and qibla (G3)
- Khatma or memorisation tracking (G4)
- AI summaries (G5)

## Open points from the checklist

1. **E3 and E4:** the saved picks were "tabs plus swipe" and "last one used". The notes override them: pills only, and al-Muyassar always opens first. This spec follows the notes.
2. **Long-press only (E1):** users need a one-time hint on first launch, such as "اضغط مطولاً على الآية لعرض التفسير". For screen readers, expose the long-press as an accessibility action ("عرض التفسير") so TalkBack users can reach it.
3. **Licences:**
   - The five classical tafsirs are public domain.
   - Al-Muyassar and the KFGQPC Hafs font are modern works by the King Fahd Complex. Free use with credit is common practice. Don't modify the font, and get permission before charging money. We are keeping KFGQPC rather than Digital Khatt V2, whose licence couldn't be verified.
   - Because the code is open source (B3), state the data and font terms separately from the code licence in the repo.
