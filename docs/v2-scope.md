# Tafaseer v2 scope

This scope dates from 25 Nov 2026, after v1.0.0 ran on a phone for the first time. v2 changes how the app looks and how the Quran is shown. The core feature stays the same: long-press an ayah to read its tafsir offline.

The team's open questions were answered on 25 Nov 2026. What's built is listed in section 6.

## 1. Madani mushaf page view

The Quran is shown page by page, like a printed 604-page Madani mushaf, and like Tarteel's page view.

- **Fonts (decided 25 Nov 2026):**
  - **Choice:** one KFGQPC Uthmanic Hafs font (242 KB) draws the Madani 15-line layout.
  - **Ruled out:** the 604 per-page QPC V2 fonts Tarteel uses, measured at 108 MB as WOFF and 98 MB as WOFF2. Almost all of that is glyph outlines, so it can't be trimmed.
  - **What changes:** lines and pages match the print exactly; word shapes and spacing are the digital Hafs font's.
  - **Licence:** QUL's page for resource 249 has no copyright information, which is one more reason not to ship those files.
- **Data:** the pipeline adds the layout to `tafaseer.db` (schema 2), from the quran.com API's per-word line numbers. No QUL login is needed.
  - `mushaf_lines`: page, line, kind (ayah, surah title, bismillah), surah, word range.
  - `mushaf_words`: id, ayah, end-of-ayah flag, Hafs text.
  - See `pipeline/README.md`, "Mushaf pages".
- **Layout:**
  - ayah lines are justified to the screen width;
  - short lines and the two opening pages are centred;
  - surah titles sit in a framed band, and the bismillah has its own line;
  - swipe right-to-left between pages.
- **Page header:** surah name, page number, juz and hizb, as in Tarteel. Bookmarking stays in the sheet header for now.
- **Long-press:** long-pressing any word highlights its whole ayah, which may cover more than one line, and opens the same tafsir sheet as v1. When the sheet steps to the next or previous ayah, the highlight follows it and the page turns if needed.
- **Navigation:** the surah index, juz and hizb list, jump to ayah, bookmarks and resume all open the right page.
- **Themes:** the text takes each theme's ink colour.
- **Still required before release:** rebuild from the official QUL downloads, as v1 also requires.

**Decided 25 Nov 2026:**
- **Mushaf edition:** the V2 (current) Madani print's page and line layout.
- **Verse list:** removed. Page view is the only way to read the Quran. The Quran font-size setting goes too, and pages only fit the screen width.
- **Accessibility:** without the verse list, each page still needs ayah-level semantics labels from `text_simple`, so screen readers can read it.

## 2. Visual design: the Dusty Green system

The [30 Juz in 7 Days](../../30-Juz-in-7-Days/robi-work-design.md) design system applies to everything outside the mushaf page: home, lists, settings, the tafsir sheet, dialogs and banners.

| Token | Value | Used for |
|---|---|---|
| Primary (`dustyGreen`) | `#416757` | selected pill, active tab, switches, sliders, links |
| Primary dark | `#2E4B3E` | pressed and selected states |
| Title text (`forestCharcoal`) | `#1E2B25` | titles, app bar |
| Body text (`bodyGray`) | `#283630` | tafsir text |
| Muted text | `#566A61` | subtitles, reading-time badges, hints |
| Canvas (`paper`) | `#FFFFFF` | screens, the sheet |
| Control surface | `#F3F7F5` | inactive pills, banners, inputs |
| Border (`mistGray`) | `#CDD9D3` | 1px borders on cards, pills, dividers |
| Secondary neutral | `#E4ECE7` | active pill fill, list number badges |

- **Geometry:**
  - flat surfaces with no shadows anywhere, and depth shown with 1px borders;
  - 4.8px corners on buttons, cards, pills, badges and dialogs;
  - 8px top corners on bottom sheets, including the tafsir sheet.
- **Interface type:** Tajawal, bundled from the reference app with its OFL licence.
- **Spacing:** a 4px grid, with 20px screen margins.
- **Changes to current screens:**
  - surah list: the round number badges become square 4.8px tiles, and the English names go;
  - continue-reading card and long-press hint: from the orange filled cards to the flat bordered style;
  - tafsir pills: the reference's neutral and active pill styles;
  - settings: Dusty Green switches and sliders.

**Decided 25 Nov 2026:**
- **Themes:** light, dark and sepia, all three kept.
  - **Light:** the reference palette above.
  - **Dark:** built from the same palette, with a forest-charcoal canvas and sage text and borders, close to Tarteel's page view.
  - **Sepia:** a warm paper background, using the same green accents and borders.
  - The mushaf glyphs take each theme's text colour.
- **Tafsir font:** Noto Naskh Arabic for the body text, Amiri for headings. Both are OFL and bundled.

## 3. Fixes from the first phone run

1. **The middle dot reads as a zero.** "مكية · ٧ آية" looks like ٧٠, "الميسر · ١ د" like ١٠ د, and "البقرة · ٦" like ٦٠. Use the Arabic comma (، ) or a spaced dash instead of `·`, everywhere.
2. **No KFGQPC font.** The Quran font was never bundled, so the text used the phone's own font and the ayah numbers were plain digits. Page view fixes this. Bundle the Hafs font anyway for the ayah text quoted in the tafsir sheet header and in copied text.
3. **Big gaps between words in Fatiha 7.** These came from justifying the text in the verse list, which v2 removes.
4. **Western digits in settings.** Line spacing shows "1.9". Use Arabic digits like the other values.
5. **English surah names in the surah list.** Remove them, because the app is Arabic only (A3).

## 4. Speed and size

- **Startup:** measure the first-launch database copy on a mid-range phone. If it takes more than about 2 s, open the database straight from an uncompressed asset, or copy it in the background while showing the last page read.
- **Size:** page fonts plus the 45 MB database. Possible savings:
  - per-tafsir zlib dictionaries, explained in the pipeline README;
  - keeping both ayah texts: `text` (Hafs) for copy and share, because glyph codes aren't readable text, and `text_simple` for screen readers;
  - Android App Bundle splits.
- **Pages:** build only the current and neighbouring pages, keep each page's lines and glyphs in a small cache, and load each page font once.
- **Target:** page turns and opening the sheet at 60 fps on a mid-range Android phone. Profile in release mode, not debug: the phone test so far was a debug APK, which is much slower.

## 5. Carried over from v1, still not built

- Find within the open entry (E9)
- Tablet side panel (E11)
- App icon (B8)
- Crash reporting (B5)
- Release signing and the final application id

## Not in v2

- Audio, recitation and memorisation tools (such as Tarteel's "Mistakes" mode)
- Translations
- Accounts and sync

## 6. Status (25 Nov 2026)

**Built, with tests passing (34 Flutter, 34 pipeline):**
- the mushaf page view (section 1);
- the Dusty Green design system in light, dark and sepia, with Tajawal, Noto Naskh Arabic and Amiri (section 2);
- all five fixes from the first phone run (section 3);
- verse list and Quran font-size setting removed.

**Added after the first phone run of v2:**
- surah titles with QUL's ornate frame and the surah names in calligraphy, plus the calligraphic bismillah, like Tarteel (QUL's quran-common and surah-name v4 fonts);
- six surah names corrected to the mushaf spelling (Tanzil wrote ابراهيم without the hamza, for example);
- jump to ayah with separate surah and ayah number fields (phone number pads have no ":");
- a long-press hint that hides itself;
- a shorter sheet header;
- Quran brackets ﴿ ﴾ in tafsir text drawn with the Hafs font.

**Tried and reverted:** stretching letters sideways to even out the spacing between words. On the phone it looked wrong, so lines are justified with the gaps only.

**Checked only off-device:** pages rendered to images with the real fonts for pages 1, 2, 50, 328 and 604. On-device speed still needs a release-mode run on a phone (section 4).

**Not started:**
- section 4 size work;
- section 5 items;
- a bookmark button in the page header.

**Next (after v2.0):** find per-ayah editions of the tafsirs, starting with al-Baghawi, whose QUL edition often comments on several ayahs in one passage (29:64–67, for example). Take one only if its size, licence and download cost are low.
