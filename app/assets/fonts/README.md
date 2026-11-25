# Fonts

## Mushaf fonts (not committed)

From the `pipeline` folder, run:

```sh
py -m tafaseer_pipeline font
```

It downloads three fonts from QUL's CDN into this folder:

| File | What it draws | Without it |
|---|---|---|
| `UthmanicHafs.ttf` | KFGQPC Uthmanic Script HAFS v18, the font the database's `qpc_hafs` text is written for | The mushaf falls back to Amiri, and end-of-ayah marks show as plain digits. |
| `QuranCommon.ttf` | QUL's ornate surah header frame (ligature `header`) and the calligraphic bismillah (U+FDFD) | Surah titles get a plain double frame, and the bismillah uses the Hafs text. |
| `SurahNames.ttf` | QUL's surah-name calligraphy (v4): `surah001`..`surah114`, plus `surah-icon` for "سورة" | Same as the row above. |

`lib/core/fonts/quran_font_loader.dart` loads them at startup, so you don't need to edit `pubspec.yaml`. Each missing file is logged:
`[tafaseer.font] ERROR assets/fonts/<file> not bundled`.

Font terms: free use is common practice. Don't modify the font, and get the King Fahd Complex's permission before charging money for the app.

## Interface fonts (committed, `ui/`)

Tajawal (interface), Noto Naskh Arabic (tafsir text) and Amiri (tafsir headings, surah names). They're OFL-licensed (see `ui/OFL.txt`) and declared in `pubspec.yaml`.
