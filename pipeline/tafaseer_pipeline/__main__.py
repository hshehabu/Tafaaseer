"""Command line: py -m tafaseer_pipeline {fetch,build,show} ..."""

import argparse
import json
import sqlite3
import sys
import zlib
from pathlib import Path

from . import config, mushaf, sources
from .build import build

_MARK = {1: ("﴿", "﴾"), 2: ("⟦سند: ", "⟧"), 3: ("[حاشية: ", "]"), 4: ("", "")}


def _fetch(_args) -> int:
    sources.quran_files()
    mushaf.page_files()
    if any(t.center for t in config.TAFSIRS):
        sources.center_db()
    for tafsir in config.TAFSIRS:
        if tafsir.center:
            continue
        if sources.qul_file(tafsir):
            print(f"{tafsir.slug}: using {sources.qul_file(tafsir)}", file=sys.stderr)
        else:
            sources.mirror_files(tafsir)
    print("All sources are cached.", file=sys.stderr)
    return 0


def _font(args) -> int:
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, url in config.MUSHAF_FONTS.items():
        font = sources._download(url, config.CACHE_DIR / "fonts" / url.rsplit("/", 1)[-1])
        out = out_dir / name
        out.write_bytes(font.read_bytes())
        print(f"Wrote {out} ({out.stat().st_size / 1e3:.0f} KB)", file=sys.stderr)
    return 0


def _show(args) -> int:
    db = Path(args.db)
    if not db.exists():
        print(f"No database at {db}. Run the build first.", file=sys.stderr)
        return 1
    con = sqlite3.connect(f"file:{db.as_posix()}?mode=ro", uri=True)
    try:
        surah, ayah = (int(x) for x in args.ayah.split(":"))
    except ValueError:
        print("Give the ayah as surah:ayah, for example 2:255", file=sys.stderr)
        return 2
    row = con.execute("SELECT id, text FROM ayahs WHERE surah=? AND ayah=?", (surah, ayah)).fetchone()
    if not row:
        print(f"No ayah {args.ayah}", file=sys.stderr)
        return 1
    ayah_id, text = row
    print(text, "\n")
    query = """SELECT t.slug, t.short_name_ar, e.first_ayah_id, e.last_ayah_id, e.words, e.words_without_isnad, e.body
               FROM tafsir_ayahs ta JOIN tafsirs t ON t.id = ta.tafsir_id JOIN tafsir_entries e ON e.id = ta.entry_id
               WHERE ta.ayah_id = ? {} ORDER BY t.sort_order"""
    params: list = [ayah_id]
    where = ""
    if args.tafsir:
        where, params = "AND t.slug = ?", [ayah_id, args.tafsir]
    for slug, name, first, last, words, words_no_isnad, body in con.execute(query.format(where), params):
        rng = con.execute("SELECT surah||':'||ayah FROM ayahs WHERE id IN (?, ?) ORDER BY id", (first, last)).fetchall()
        span = rng[0][0] if first == last else f"{rng[0][0]}–{rng[-1][0].split(':')[1]}"
        print(f"=== {name} ({slug}) · {span} · {words:,} words, {words_no_isnad:,} without isnad")
        doc = json.loads(zlib.decompress(body))
        for p in doc["p"]:
            if p["k"] == "hr":
                print("   * * *")
                continue
            parts = []
            for kind, txt in p["s"]:
                if (kind == 2 and args.hide_isnad) or (kind == 3 and args.hide_notes):
                    parts.append("…" if kind == 2 else "")
                    continue
                open_, close = _MARK.get(kind, ("", ""))
                parts.append(open_ + txt + close)
            prefix = {"h": "## ", "poem": "   ~ "}.get(p["k"], "")
            print(prefix + "".join(parts))
        print()
    return 0


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="tafaseer_pipeline", description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("fetch", help="download and cache all sources").set_defaults(func=_fetch)

    b = sub.add_parser("build", help="build the app database (fetches missing sources)")
    b.add_argument("--out", default=str(config.DEFAULT_OUT), help="output .db path")
    b.add_argument("--only", help="comma-separated tafsir slugs, e.g. muyassar,saadi")
    b.add_argument("--allow-gaps", action="store_true", help="warn instead of failing when ayahs lack text")
    b.set_defaults(func=lambda a: build(Path(a.out), a.only.split(",") if a.only else None, a.allow_gaps))

    f = sub.add_parser("font", help="download the mushaf fonts into the Flutter app")
    f.add_argument("--out", default=str(config.APP_FONTS_DIR), help="folder for the font files")
    f.set_defaults(func=_font)

    s = sub.add_parser("show", help="print the cleaned tafsir for one ayah from a built database")
    s.add_argument("ayah", help="surah:ayah, e.g. 2:255")
    s.add_argument("--tafsir", help="one slug: " + ", ".join(t.slug for t in config.TAFSIRS))
    s.add_argument("--db", default=str(config.DEFAULT_OUT))
    s.add_argument("--hide-isnad", action="store_true")
    s.add_argument("--hide-notes", action="store_true")
    s.set_defaults(func=_show)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
