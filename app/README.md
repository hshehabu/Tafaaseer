# Tafaseer app

This is the Flutter app: a Quran verse list where long-pressing an ayah opens a sheet with six tafsirs, offline. The scope is in [../docs/v1-scope.md](../docs/v1-scope.md), and the data comes from [../pipeline](../pipeline/README.md).

## Run it

```sh
# 1. Build the content database once (about 90 s; needs Python 3.10+)
cd pipeline
py -m tafaseer_pipeline build --out ../app/assets/db/tafaseer.db

# 2. Optional: add the Quran font, see assets/fonts/README.md

# 3. Run
cd ../app
flutter run
```

If you skip step 1, the app opens on an error screen. In debug builds that screen says the database asset is missing and to run the pipeline.

## Architecture: feature-first clean architecture

```
lib/
  main.dart                 creates preferences, starts ProviderScope
  app/                      wiring: MaterialApp, theme, startup gate
  core/                     shared, feature-agnostic code
    database/               copy the bundled DB, open it read-only, providers
    domain/ayah_ref.dart    the one value type every feature shares
    arabic/ l10n/ logging/ error/ config/ storage/ fonts/ widgets/
  features/
    quran/                  surah index, juz/hizb list, verse reader, jump, resume
    tafsir/                 the long-press sheet (the core feature)
    bookmarks/              bookmark toggle and list
    settings/               theme, font sizes, tashkeel, isnad
```

Every feature has the same three layers:

| Layer | Contains | May import |
|---|---|---|
| `domain/` | entities, repository interfaces, use cases | Dart and `core/domain` only. No Flutter widgets, SQL or packages. |
| `data/` | data sources (all the SQL), row mappers, repository implementations | its own `domain/`, `core/` |
| `presentation/` | Riverpod providers, pages, widgets | its own `domain/`, `core/`, and the public parts of other features (below) |

**Rules:**
- **Between features:** a feature may use another feature's domain entities and public entry points, such as `showTafsirSheet` or `ReaderPage.route`, and read its providers. It never imports another feature's `data/`.
- **SQL:** lives only in the `data/datasources/*_local_data_source.dart` files.
- **Use cases:** only where there is real logic:
  - `GetAyahTafsirs` picks the opening pill.
  - `BuildShareText` builds the copy/share text.
  - `ToggleBookmark` adds or removes a bookmark.
  - `ResolveAyahRef` checks a typed reference.

  Plain reads go straight from a provider to the repository interface. Wrapping them in pass-through classes would only add files to step through.
- **Wiring:** each feature wires itself in its `presentation/providers` file (data source, then repository, then use cases). Tests replace one provider, usually `readyContentDatabaseProvider` or `preferencesProvider`, and get the whole real stack on top of it.
- **Two kinds of storage, never mixed:**
  - The **content database** (Quran and tafsirs) is read-only and replaced on app updates.
  - **User data** (settings, bookmarks, last position) lives in `SharedPreferencesWithCache`.

### What happens on a long-press

```
AyahTile.onLongPress
  -> showTafsirSheet(ayah)                         tafsir/presentation/tafsir_sheet.dart
     -> ayahTafsirsProvider(ayahId)                 FutureProvider.autoDispose.family
        -> GetAyahTafsirs -> TafsirRepository.getEntriesForAyah
           -> TafsirLocalDataSource.entriesForAyah  one indexed query, ~0.1 ms
     -> tafsirDocumentProvider(entryId)             for the selected pill
        -> TafsirRepository.getDocument             cached; otherwise zlib + JSON decode,
                                                    on a background isolate above 16 KB
     -> SliverList of TafsirParagraphView           built lazily, paragraph by paragraph
```

## Fast to fetch, fast to load

- **Database access:** `sqlite3` uses FFI, with synchronous queries, no platform channel, and prepared statements cached per query string.
- **Long-press lookup:** about 0.1 ms with every join, through the `(ayah_id, tafsir_id)` primary key.
- **Decoding tafsir text:** most entries take 0–2 ms, and the largest about 10 ms, on a desktop host (`test/real_database_test.dart` prints the slowest). Decoded documents are kept in a 24-entry cache, so switching pills or stepping back to an ayah is instant.
- **Startup:** preferences load before the first frame, so the theme is right immediately. The 45 MB database is copied into the app's cache directory on first launch only (a second or two, with a progress screen). It's copied again when `ContentDbConfig.bundleVersion` changes or the file is damaged.
- **Long entries:** the sheet builds paragraphs lazily, which matters for al-Qurtubi's 108,000-character entries.

## Debugging

- **Logs:** every log line is tagged `[tafaseer.<area>]`: `db`, `font`, `startup`, `tafsir`, `provider`. Filter `flutter run` output by tag. Any failed provider is logged with its name by `AppProviderObserver`.
- **Inspect the database on a device:** the log prints its path on startup. On a debug build:
  `adb exec-out run-as app.tafaseer.tafaseer cat cache/tafaseer.db > tafaseer.db`
  then open it with any SQLite browser, or `py -m tafaseer_pipeline show 2:255 --db tafaseer.db`.
- **Startup failures** show the technical reason on screen in debug builds, with a retry button.
- **User data** is plain preferences keys: `settings.*`, `bookmarks.v1`, `reading.last_position`.

## Tests

```sh
flutter test        # 28 tests: data layer on an in-memory DB, widgets, and the real DB if built
flutter analyze     # strict casts/inference + extra lints (analysis_options.yaml)
```

`test/helpers/content_db_fixture.dart` builds a small database with the pipeline's exact schema, so repository tests use real SQL without the 45 MB file.

## Shipping checklist

1. **Data:** rebuild the database from the official QUL exports, not the GitHub mirror (see ../docs/v1-scope.md).
2. **Database version:** whenever the shipped database changes, bump `ContentDbConfig.bundleVersion` in `lib/core/config/app_config.dart`.
3. **Font:** add the KFGQPC font file (assets/fonts/README.md).
4. **Application id:** it's currently `app.tafaseer.tafaseer`. Choose the final id before the first Play Store upload, because it can never change after that.
5. **Release signing:** set up signing in `android/app/build.gradle.kts`. It currently uses the debug keys.

## Not built yet (v1 scope)

- Find within the open tafsir entry (E9).
- Side-by-side layout on tablets (E11).
- App icon and name artwork (B8).
- Crash reporting (B5).
