"""Write the app database and check it."""

import json
import sqlite3
import sys
import time
import zlib
from datetime import datetime, timezone
from pathlib import Path

from . import BODY_FORMAT_VERSION, SCHEMA_VERSION, center, config, loaders, mushaf, quran, sources
from .clean import clean_entry

SCHEMA = """
CREATE TABLE meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
CREATE TABLE surahs (
  id            INTEGER PRIMARY KEY,
  name_ar       TEXT NOT NULL,
  name_translit TEXT NOT NULL,
  revelation    TEXT NOT NULL CHECK (revelation IN ('meccan', 'medinan')),
  ayah_count    INTEGER NOT NULL,
  first_ayah_id INTEGER NOT NULL
);
CREATE TABLE ayahs (
  id          INTEGER PRIMARY KEY,          -- 1..6236 in mushaf order
  surah       INTEGER NOT NULL REFERENCES surahs(id),
  ayah        INTEGER NOT NULL,
  text        TEXT NOT NULL,                -- KFGQPC Hafs text, ends with the ayah number
  text_simple TEXT NOT NULL,                -- no diacritics; for search and sharing as plain text
  juz         INTEGER NOT NULL,
  hizb        INTEGER NOT NULL,
  rub         INTEGER NOT NULL,             -- quarter of a hizb, 1..240
  page        INTEGER NOT NULL,             -- Madani mushaf page, 1..604
  sajda       INTEGER NOT NULL DEFAULT 0,
  UNIQUE (surah, ayah)
);
CREATE TABLE tafsirs (
  id            INTEGER PRIMARY KEY,
  slug          TEXT NOT NULL UNIQUE,
  name_ar       TEXT NOT NULL,
  short_name_ar TEXT NOT NULL,              -- pill label
  author_ar     TEXT NOT NULL,
  died_hijri    INTEGER,
  sort_order    INTEGER NOT NULL,
  is_default    INTEGER NOT NULL DEFAULT 0,
  source        TEXT NOT NULL,
  entry_count   INTEGER NOT NULL
);
CREATE TABLE tafsir_entries (
  id                  INTEGER PRIMARY KEY,
  tafsir_id           INTEGER NOT NULL REFERENCES tafsirs(id),
  first_ayah_id       INTEGER NOT NULL,     -- shared commentary covers first..last
  last_ayah_id        INTEGER NOT NULL,
  words               INTEGER NOT NULL,     -- for the reading-time badge
  words_without_isnad INTEGER NOT NULL,
  body                BLOB NOT NULL         -- zlib-compressed UTF-8 JSON, see README
);
CREATE TABLE tafsir_ayahs (
  ayah_id   INTEGER NOT NULL,
  tafsir_id INTEGER NOT NULL,
  entry_id  INTEGER NOT NULL REFERENCES tafsir_entries(id),
  PRIMARY KEY (ayah_id, tafsir_id)              -- the long-press reads all tafsirs of one ayah
) WITHOUT ROWID;
CREATE TABLE mushaf_lines (                    -- Madani mushaf, 604 pages x 15 lines (pages 1-2 shorter)
  page       INTEGER NOT NULL,
  line       INTEGER NOT NULL,
  kind       TEXT NOT NULL CHECK (kind IN ('ayah', 'surah', 'basmala')),
  surah      INTEGER NOT NULL,                 -- for 'surah' and 'basmala' lines, else 0
  first_word INTEGER NOT NULL,                 -- mushaf_words.id range for 'ayah' lines, else 0
  last_word  INTEGER NOT NULL,
  PRIMARY KEY (page, line)
) WITHOUT ROWID;
CREATE TABLE mushaf_words (
  id      INTEGER PRIMARY KEY,                 -- 1.. in mushaf order
  ayah_id INTEGER NOT NULL,
  is_end  INTEGER NOT NULL,                    -- 1 for the end-of-ayah number
  text    TEXT NOT NULL                        -- KFGQPC Hafs text of the word
);
"""


def _source_label(tafsir: config.Tafsir, qul_path: Path | None) -> str:
    if qul_path:
        return f"QUL resource {tafsir.qul_id} ({qul_path.name})"
    return f"QUL resource {tafsir.qul_id} via spa5k/tafsir_api@{config.MIRROR_COMMIT[:12]}"


def _load_raw(tafsir: config.Tafsir, index: loaders.AyahIndex) -> tuple[list[loaders.RawEntry], str]:
    if tafsir.center:
        entries = center.load(sources.center_db(), tafsir.center, index)
        return entries, f"{config.CENTER_CREDIT} ({tafsir.center.table}@{config.CENTER_REVISION[:12]})"
    qul_path = sources.qul_file(tafsir)
    if qul_path is None:
        entries = loaders.load_mirror(sources.mirror_files(tafsir), index)
    elif qul_path.suffix == ".json":
        entries = loaders.load_qul_json(qul_path, index)
    else:
        entries = loaders.load_qul_sqlite(qul_path, index)
    return entries, _source_label(tafsir, qul_path)


def build(out: Path, only: list[str] | None = None, allow_gaps: bool = False) -> int:
    started = time.time()
    tafsirs = [t for t in config.TAFSIRS if not only or t.slug in only]
    unknown = set(only or []) - {t.slug for t in config.TAFSIRS}
    if unknown:
        print(f"unknown tafsir: {', '.join(sorted(unknown))}", file=sys.stderr)
        return 2

    print("Quran text and metadata ...", file=sys.stderr)
    surahs, ayahs = quran.load(sources.quran_files())
    index = loaders.AyahIndex([s.ayah_count for s in surahs])
    surah_of = {a.id: a.surah for a in ayahs}

    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = out.with_suffix(".building")
    tmp.unlink(missing_ok=True)
    con = sqlite3.connect(tmp)
    con.executescript("PRAGMA page_size = 4096; PRAGMA journal_mode = OFF; PRAGMA synchronous = OFF;")
    con.executescript(SCHEMA)
    con.executemany("INSERT INTO surahs VALUES (?,?,?,?,?,?)",
                    [(s.id, s.name_ar, s.name_translit, s.revelation, s.ayah_count, s.first_ayah_id) for s in surahs])
    con.executemany("INSERT INTO ayahs VALUES (?,?,?,?,?,?,?,?,?,?)",
                    [(a.id, a.surah, a.ayah, a.text, a.text_simple, a.juz, a.hizb, a.rub, a.page, int(a.sajda))
                     for a in ayahs])

    report: dict = {"tafsirs": {}}
    errors: list[str] = []

    print("Mushaf page layout ...", file=sys.stderr)
    words = mushaf.load_words(mushaf.page_files(), {f"{a.surah}:{a.ayah}": a.id for a in ayahs})
    lines = mushaf.build_lines(words, {s.id: s.first_ayah_id for s in surahs})
    errors += mushaf.check(words, lines, {a.id: a.text for a in ayahs})
    con.executemany("INSERT INTO mushaf_words VALUES (?,?,?,?)", [(w.id, w.ayah_id, int(w.is_end), w.text) for w in words])
    con.executemany("INSERT INTO mushaf_lines VALUES (?,?,?,?,?,?)",
                    [(l.page, l.line, l.kind, l.surah, l.first_word, l.last_word) for l in lines])
    report["mushaf"] = {"pages": mushaf.PAGES, "lines": len(lines), "words": len(words)}
    print(f"  {mushaf.PAGES} pages, {len(lines):,} lines, {len(words):,} words", file=sys.stderr)
    for order, tafsir in enumerate(tafsirs, start=1):
        print(f"{tafsir.slug} ...", file=sys.stderr)
        tafsir_id = config.TAFSIRS.index(tafsir) + 1
        raw_entries, source = _load_raw(tafsir, index)
        attached = loaders.attach_gaps_to_neighbours(raw_entries, index) if tafsir.attach_gaps_to_previous else 0
        stats = {"entries": 0, "ayahs": 0, "attached_gaps": attached, "words": 0, "isnad_words": 0, "isnads": 0, "notes": 0,
                 "notes_unplaced": 0, "unclosed_brackets": 0, "cross_surah_entries": 0, "empty_after_clean": 0,
                 "raw_bytes": 0, "body_bytes": 0, "longest_entry_words": 0, "longest_entry": ""}
        covered: dict[int, int] = {}
        entry_rows, map_rows = [], []
        for raw in raw_entries:
            if not raw.ayah_ids:
                continue
            cleaned = clean_entry(raw.text)
            st = cleaned.pop("_stats")
            if not cleaned["p"]:
                stats["empty_after_clean"] += 1
                continue
            first, last = raw.ayah_ids[0], raw.ayah_ids[-1]
            if surah_of[first] != surah_of[last]:
                stats["cross_surah_entries"] += 1
            payload = json.dumps(cleaned, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
            body = zlib.compress(payload, 9)
            entry_id = len(entry_rows) + 1 + tafsir_id * 1_000_000
            entry_rows.append((entry_id, tafsir_id, first, last, st["words"], st["words_without_isnad"], body))
            for ayah_id in raw.ayah_ids:
                if ayah_id in covered:
                    errors.append(f"{tafsir.slug}: ayah {index.key_of[ayah_id]} is in two entries")
                    continue
                covered[ayah_id] = entry_id
                map_rows.append((ayah_id, tafsir_id, entry_id))
            stats["entries"] += 1
            stats["words"] += st["words"]
            stats["isnad_words"] += st["words"] - st["words_without_isnad"]
            stats["isnads"] += st["isnads"]
            stats["notes"] += st["notes"]
            stats["notes_unplaced"] += st["notes"] - st["notes_placed"]
            stats["unclosed_brackets"] += st["unclosed_brackets"]
            stats["raw_bytes"] += len(raw.text.encode("utf-8"))
            stats["body_bytes"] += len(body)
            if st["words"] > stats["longest_entry_words"]:
                s, a = index.key_of[first]
                stats["longest_entry_words"], stats["longest_entry"] = st["words"], f"{s}:{a}"

        missing = [index.key_of[i] for i in range(1, index.total + 1) if i not in covered]
        stats["ayahs"] = len(covered)
        stats["missing_ayahs"] = len(missing)
        if missing:
            sample = ", ".join(f"{s}:{a}" for s, a in missing[:10])
            msg = f"{tafsir.slug}: {len(missing)} ayahs have no tafsir text (first: {sample})"
            (print(f"  warning: {msg}", file=sys.stderr) if allow_gaps else errors.append(msg))
        con.executemany("INSERT INTO tafsir_entries VALUES (?,?,?,?,?,?,?)", entry_rows)
        con.executemany("INSERT INTO tafsir_ayahs VALUES (?,?,?)", map_rows)
        con.execute("INSERT INTO tafsirs VALUES (?,?,?,?,?,?,?,?,?,?)",
                    (tafsir_id, tafsir.slug, tafsir.name_ar, tafsir.short_name_ar, tafsir.author_ar,
                     tafsir.died_hijri, order, int(tafsir.is_default), source, stats["entries"]))
        stats["source"] = source
        report["tafsirs"][tafsir.slug] = stats
        _print_stats(tafsir.slug, stats)

    built_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    meta = {
        "schema_version": SCHEMA_VERSION,
        "body_format_version": BODY_FORMAT_VERSION,
        "built_at": built_at,
        "quran_text_source": "KFGQPC Hafs text via quran.com API v4 (qpc_hafs)",
        "quran_metadata_source": "Tanzil.net quran-data.xml (CC BY 3.0)",
        "mushaf_layout_source": "Madani 15-line layout via quran.com API v4 (word line numbers)",
        "tafsir_source": "Quranic Universal Library (qul.tarteel.ai) by Tarteel: al-Muyassar, al-Qurtubi; "
                         + config.CENTER_CREDIT + ": al-Mukhtasar, al-Sa'di, al-Baghawi, Ibn Kathir, al-Tabari",
    }
    con.executemany("INSERT INTO meta VALUES (?, ?)", [(k, str(v)) for k, v in meta.items()])
    con.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
    con.commit()
    con.execute("VACUUM")
    con.close()

    if errors:
        print("\nBuild failed:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print(f"The partial database is at {tmp}", file=sys.stderr)
        return 1

    tmp.replace(out)
    report.update(meta)
    report["db_bytes"] = out.stat().st_size
    # Always next to the default output, so a build into the app never bundles the report.
    report_path = config.DEFAULT_OUT.parent / "report.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nWrote {out} ({out.stat().st_size / 1e6:.1f} MB) in {time.time() - started:.0f}s", file=sys.stderr)
    print(f"Report: {report_path}", file=sys.stderr)
    return 0


def _print_stats(slug: str, s: dict) -> None:
    hidden = 100 * s["isnad_words"] / s["words"] if s["words"] else 0
    if s.get("attached_gaps"):
        print(f"  {s['attached_gaps']} ayahs without their own text joined the commentary before them", file=sys.stderr)
    print(f"  {s['entries']:>5} entries, {s['ayahs']} ayahs, {s['words']:,} words, "
          f"{s['notes']:,} footnotes, {s['isnads']:,} isnads ({hidden:.0f}% of words), "
          f"{s['body_bytes'] / 1e6:.1f} MB compressed", file=sys.stderr)
    if s["notes_unplaced"] or s["unclosed_brackets"] or s["cross_surah_entries"] or s["empty_after_clean"]:
        print(f"  check: unplaced notes {s['notes_unplaced']}, stray [[ or ]] {s['unclosed_brackets']}, "
              f"entries crossing a surah {s['cross_surah_entries']}, empty after cleaning {s['empty_after_clean']}",
              file=sys.stderr)
