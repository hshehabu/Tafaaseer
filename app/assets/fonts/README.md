# Quran font

The app shows the Quran in the **KFGQPC Uthmanic Script HAFS** font (decision F4). The font isn't committed to the repo.

1. Download the Hafs font from the King Fahd Complex: <https://fonts.qurancomplex.gov.sa/>.
2. Save it here as `UthmanicHafs.ttf`.
3. Rebuild the app. You don't need to edit `pubspec.yaml`, because `lib/core/fonts/quran_font_loader.dart` loads the font at startup.

Without the file, the app still builds and runs, and the Quran text uses the system Arabic font. The log then shows:
`[tafaseer.font] ERROR assets/fonts/UthmanicHafs.ttf not bundled`.

Font terms: free use is common practice. Don't modify the font, and get the King Fahd Complex's permission before charging money for the app.
