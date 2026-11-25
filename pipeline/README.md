# Tafaseer data pipeline

This pipeline builds `build/tafaseer.db`, the SQLite database that ships inside the app. The database holds:

- the Quran in KFGQPC Hafs text, with surah, juz, hizb, quarter, page and sajda data;
- the Madani mushaf page layout: 604 pages of 15 lines, every word placed on its line;
- seven tafsirs, cleaned for reading: al-Muyassar, al-Mukhtasar, al-Sa'di, al-Baghawi, Ibn Kathir, al-Qurtubi and al-Tabari.

The pipeline needs only Python 3.10+ and its standard library.

## Run it

```sh
cd pipeline
py -m tafaseer_pipeline build                      # downloads missing sources, then builds (about 90 s once cached)
py -m tafaseer_pipeline build --out ../app/assets/db/tafaseer.db   # build straight into the Flutter app
py -m tafaseer_pipeline font                       # put the mushaf fonts into the Flutter app
py -m tafaseer_pipeline show 2:255                 # print the cleaned tafsirs for one ayah
py -m tafaseer_pipeline show 112:1 --tafsir tabari --hide-isnad
py -m unittest discover -s tests -t .              # tests
```

On macOS and Linux, use `python3` instead of `py`.

Other options:

- `build --only muyassar,saadi` builds a subset.
- `build --allow-gaps` turns missing ayahs into warnings instead of errors.
- `fetch` only downloads the sources.

The first build downloads about 320 MB into `cache/` (most of it the Tafsir Center database). Each build also writes `build/report.json` with per-tafsir and mushaf statistics, wherever `--out` points.

## Sources

| Data | Source | Notes |
|---|---|---|
| Tafsirs, per ayah | [Tafsir Center for Quranic Studies](https://tafsir.net) database on [Hugging Face](https://huggingface.co/datasets/tafsircenter/tafsir-mcp-data), CC BY 4.0 | al-Mukhtasar, al-Sa'di, al-Baghawi, Ibn Kathir, al-Tabari. One 234 MB SQLite file, pinned to one revision in `config.py`. Its editions comment ayah by ayah, where QUL's often share one passage across several ayahs (al-Baghawi: 4 shared ayahs instead of 5,608). See "Tafsir Center markup" below. |
| Tafsirs | [QUL](https://qul.tarteel.ai) (Tarteel) IDs 38 and 23 | QUL downloads need a login. If you put the downloaded files in `input/qul/` as `<slug>.json` or `<slug>.sqlite` (for example `input/qul/tabari.json`), the pipeline uses them. Otherwise it falls back to [spa5k/tafsir_api](https://github.com/spa5k/tafsir_api), a public mirror of the same QUL data, pinned to one commit in `config.py`. |
| Quran text | quran.com API v4, `qpc_hafs` and `uthmani_simple` | `qpc_hafs` is the text that matches the KFGQPC Hafs font. Each ayah ends with its number. |
| Structure | [Tanzil](https://tanzil.net) `quran-data.xml`, CC BY 3.0 | Surah names, Meccan or Medinan, juz, hizb quarters, pages, sajdas. Six names are corrected to the mushaf spelling (`NAME_FIXES` in `quran.py`), for example ابراهيم to إبراهيم. |
| Mushaf layout | quran.com API v4, `verses/by_page` with each word's `line_number` | The Madani 15-line layout. See "Mushaf pages" below. |
| Mushaf fonts | KFGQPC Uthmanic Script HAFS v18, and QUL's quran-common and surah-name (v4) fonts, from QUL's CDN | `py -m tafaseer_pipeline font` copies them into the app. Not committed. |

QUL is used for al-Muyassar (QUL's is the revised edition, with surah introductions and ﴿﴾-marked quotes) and al-Qurtubi (not in the Tafsir Center database).

The slugs are `muyassar`, `mukhtasar`, `saadi`, `baghawi`, `ibn-kathir`, `qurtubi` and `tabari`.

Neither QUL loader has been run on a real QUL export yet, because the downloads need a login:

- **QUL SQLite** exports use the table `tafsir(ayah_key, group_ayah_key, from_ayah, to_ayah, ayah_keys, text)`. This column layout comes from the open-source [quran-offline-mobile](https://github.com/hndrwn-dk/quran-offline-mobile) app, which reads QUL exports in production. `tests/test_loaders.py` tests the loader against it.
- **QUL JSON** follows QUL's documented format.
- **HTML:** the `text` is HTML, hard-wrapped inside `<p>`, with `<h2>` section titles. When you first build from real QUL files, check for `class="qpc-hafs"` blocks (embedded ayah text). That app drops them.

## What the cleaning does

| Step | Why |
|---|---|
| Shared commentary becomes one entry covering a range of ayahs. | The app shows "Commentary for 2:1–5" instead of repeating the text on each ayah. |
| Al-Sa'di's ayahs without their own text join the commentary before them. | He comments on several ayahs at once, and 63 ayahs have no separate text. This applies to al-Sa'di only, so real gaps elsewhere still fail the build. |
| Editor footnotes `[[…]]` become NOTE spans. | They are shown behind a small marker. A line that is only a footnote becomes an `ed` paragraph. |
| Quran quotes `﴿…﴾` and `{…}` become QURAN spans without their delimiters. | Every tafsir looks the same, and the app adds ﴿ ﴾. |
| Narrator chains become ISNAD spans. | Lets the app hide chains. See below. |
| Headings, poetry lines and dividers are detected. | Better layout: titles in bold, verse centred. |
| Latin commas and semicolons in Arabic text become `،` and `؛`, spacing is fixed, and tatweel inside words and manuscript folio marks (`٦/أ`) are removed. | Al-Sa'di uses Latin commas throughout. |
| HTML tags are stripped and entities unescaped. | QUL exports may contain `<b>` and `<p>`. |

The text itself is never rewritten. Diacritics are left in, and the app strips them when the user turns tashkeel off.

### Narrator chains (isnad)

`isnad.py` finds runs of transmission words (حدثنا، أخبرنا، ثنا، عن، أنا …) separated by short narrator names. It hides everything up to the last narrator, who stays visible:

> ~~حدثنا ابن حميد، قال: ثنا سلمة، عن ابن إسحاق،~~ عن ابن عباس قال: …

When unsure, it stops early, because hiding real content is worse than leaving a chain visible. A chain stops at any of these:

- a colon followed by narrated text;
- the words أنّ, أنه or يقول;
- a Quran quote;
- a gap longer than 12 words.

The detector was checked by hand against three random samples of 30 hidden chains:

- The first two samples found three cases that hid real content: "إنا نراك", "أخبرني عن الوضوء", and "حدثنا رسول الله ﷺ … وأنا أنتظر".
- All three are fixed, and each one is now a test in `tests/test_isnad.py`.
- The third sample found none.

It hides 16% of al-Tabari's words, 6–7% of Ibn Kathir's and al-Baghawi's, and almost none of the others'. Rare mistakes are still possible, so the app always shows hidden chains as a tappable marker.

## Tafsir Center markup

`center.py` rewrites the Tafsir Center texts into the markup the cleaner already understands, then they go through the same cleaning as QUL's:

- **Footnotes:** `¬ … ¥` becomes `[[ … ]]`, so they turn into footnote markers. These hold manuscript variants and hadith sourcing and grading.
- **The quoted ayah at the start** (`{… (64)}.`) is dropped, because the app shows the ayah already. Al-Sa'di's repeated `{64}` marker goes with it.
- **Ayah numbers inside quotes** become Arabic digits: `(30)` becomes `(٣٠)`.
- **Al-Tabari's 11 old-style ayahs** (for example 112:1–4) quote the Quran in spaced parentheses `( … )`. These become quotes only in ayahs that have no braces at all.
- **Ayahs explained together with the one before:** in the source, their row holds only their own quote (al-Baghawi 3:5) or an empty `<br>` (al-Tabari 26:16), and the ayah before quotes both. Such an ayah joins the entry before it.

## Mushaf pages

`mushaf.py` downloads the 604 pages (cached in `cache/mushaf/`) and builds the page layout the app draws with the Hafs font:

- **Words and lines:** the API gives every word with its line number. Words of one line are consecutive, so a line is stored as a word-id range.
- **Pages are counted, not trusted:** the API sometimes gives the first ayah of a page the previous page's number, while its line numbers are right. In mushaf order, a line number that goes down starts a new page. The result matches Tanzil's page boundaries for all 6,236 ayahs.
- **Title and bismillah lines:** the API has no rows for them. Each run of empty lines before a surah's first word becomes a title line, then a bismillah line (none for surahs 1 and 9). Any other empty line fails the build.
- **Checks:** the words of every ayah must join to its `text` (ignoring spaces, since a few words are split differently and the sajda mark ۩ is a word of its own), and there must be 114 titles and 112 bismillahs.

The layout comes from the V2 Madani print. The app draws it with the single KFGQPC Hafs font, not the 604 per-page V2 fonts (about 100 MB), so line breaks match the print and word shapes are the digital Hafs font's.

## Database format (schema version 2)

`PRAGMA user_version` holds the schema version, and the `meta` table holds `schema_version`, `body_format_version`, `built_at` and the source credits.

| Table | Rows | Purpose |
|---|---|---|
| `surahs` | 114 | `name_ar`, `name_translit`, `revelation` (`meccan` or `medinan`), `ayah_count`, `first_ayah_id` |
| `ayahs` | 6,236 | `id` 1..6236, `surah`, `ayah`, `text` (KFGQPC Hafs), `text_simple`, `juz`, `hizb`, `rub`, `page`, `sajda` |
| `tafsirs` | 6 | `slug`, `name_ar`, `short_name_ar` (pill label), `author_ar`, `died_hijri`, `sort_order` (pill order), `is_default` (al-Muyassar) |
| `tafsir_entries` | ~22,000 | `first_ayah_id`..`last_ayah_id`, `words`, `words_without_isnad`, `body` |
| `tafsir_ayahs` | 37,416 | maps (`ayah_id`, `tafsir_id`) to `entry_id`; keyed by ayah first, so one lookup returns all six tafsirs |
| `mushaf_lines` | 9,046 | (`page`, `line`) → `kind` (`ayah`, `surah`, `basmala`), `surah` for title and bismillah lines, `first_word`..`last_word` for ayah lines |
| `mushaf_words` | 83,665 | `id` in mushaf order, `ayah_id`, `is_end` (the end-of-ayah number), `text` (KFGQPC Hafs) |

Schema 2 added the two `mushaf_` tables. A page loads with two indexed queries, about 0.2 ms:

```sql
SELECT line, kind, surah, first_word, last_word FROM mushaf_lines WHERE page = ? ORDER BY line;
SELECT id, ayah_id, is_end, text FROM mushaf_words WHERE id BETWEEN ? AND ?;  -- first and last word of the page
```

The bismillah is part of ayah 1:1 only. The app draws a bismillah header above every other surah except surah 9.

The long-press query takes about 0.03 ms:

```sql
SELECT t.id, t.short_name_ar, e.first_ayah_id, e.last_ayah_id, e.words, e.words_without_isnad, e.body
FROM tafsir_ayahs ta
JOIN tafsirs t ON t.id = ta.tafsir_id
JOIN tafsir_entries e ON e.id = ta.entry_id
WHERE ta.ayah_id = ?
ORDER BY t.sort_order;
```

### `body`

`body` is zlib-compressed UTF-8 JSON. In Dart: `jsonDecode(utf8.decode(zlib.decode(body)))`.

```json
{"v": 1, "p": [
  {"k": "h",  "s": [[0, "القول في تأويل قوله: "], [1, "قُلْ هُوَ اللَّهُ أَحَدٌ"]]},
  {"k": "p",  "s": [[2, "حدثنا ابن حميد، قال: ثنا سلمة، "], [0, "عن ابن إسحاق قال: …"], [3, "في المطبوعة: …"]]},
  {"k": "poem", "s": [[0, "صدر البيت ... عجز البيت"]]},
  {"k": "hr", "s": []},
  {"k": "ed", "s": [[3, "هذه الآية لم يتكلم عليها المؤلف …"]]}
]}
```

| `k` (paragraph) | Render as |
|---|---|
| `p` | normal paragraph |
| `h` | heading |
| `poem` | centred verse; split hemistichs on `...` |
| `hr` | divider |
| `ed` | an editor's note shown in a muted style; its NOTE spans are visible |

| span type | Meaning | Render as |
|---|---|---|
| 0 | text | as is |
| 1 | Quran quote | wrap in ﴿ ﴾, Quran style |
| 2 | narrator chain | collapse to a tappable marker when "hide isnad" is on |
| 3 | editor footnote | small tap-to-show marker (except in `ed` paragraphs) |
| 4 | sura reference, e.g. `[البقرة: ٢٨١]` | muted, smaller |

The reading-time badge is `words / 150` minutes, or `words_without_isnad / 150` when chains are hidden.

## Size

The database is 53.8 MB on disk: about 35 MB of compressed tafsir text, 2 MB of Quran text, 2.5 MB of mushaf layout, and per-row SQLite overhead. The bodies are already compressed, so the APK only shrinks it to about 37 MB. If size becomes a problem, per-tafsir zlib dictionaries (Dart's `ZLibDecoder` supports `dictionary`) would shrink the short entries the most.

## Licences and credits

The credits page (B7) must name:

- the Tafsir Center for Quranic Studies (tafsir.net) for al-Mukhtasar, al-Sa'di, al-Baghawi, Ibn Kathir and al-Tabari (CC BY 4.0: credit required);
- QUL / Tarteel for al-Muyassar and al-Qurtubi;
- the King Fahd Complex for al-Muyassar and the Hafs text and font;
- quran.com for the mushaf page layout;
- Tanzil (CC BY 3.0) for the Quran metadata.

The five classical tafsirs are public domain. Al-Muyassar and the KFGQPC font are King Fahd Complex works: free use with credit is common practice, but ask for permission before charging money. This pipeline's code can carry the repository's code licence. The data it downloads keeps its own terms.
