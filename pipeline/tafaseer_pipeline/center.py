"""Read tafsirs from the Tafsir Center database and bring their markup in line with QUL's.

The Tafsir Center (tafsir.net) editions differ from QUL's in markup only:
- editor footnotes are wrapped in "¬ … ¥" (QUL uses "[[ … ]]");
- an entry starts with the ayah it explains, quoted in full with its number:
  "{وَمَا هَذِهِ الْحَيَاةُ ... (64)}." The app shows the ayah already, so it is dropped;
- al-Sa'di then repeats the ayah number in braces, "{64}" or "{64 - 65}";
- ayah numbers inside Quran quotes are Western digits in parentheses, "(30)";
- al-Tabari breaks paragraphs with <br>, and a few of its ayahs (11 of 6,236, for example
  112:1-4) quote the Quran in spaced parentheses "( … )" instead of braces.
"""

import re
import sqlite3
from pathlib import Path

from . import config
from .loaders import AyahIndex, RawEntry, is_placeholder

_NOTE_RE = re.compile(r"¬(.*?)¥", re.S)
_LEADING_AYAH_RE = re.compile(r"^\s*(?:<br\s*/?>\s*)*\{[^{}]*\(\d+\)\s*\}\s*[.:]?\s*")
_AYAH_NUMBER_BRACES_RE = re.compile(r"\{\s*(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?\s*\}\s*")
_QUOTE_RE = re.compile(r"\{[^{}]*\}")
_NUMBER_IN_QUOTE_RE = re.compile(r"\((\d{1,3})\)")
_SPACED_PARENS_QUOTE_RE = re.compile(r"\(\s([^()]{3,}?)\s\)")
_ARABIC_DIGITS = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")


def prepare(text: str) -> str:
    """Rewrite one Tafsir Center text into the markup clean.clean_entry understands."""
    text = text.replace("﻿", "")
    text = _NOTE_RE.sub(lambda m: "[[" + m.group(1).replace("[[", "[").replace("]]", "]") + "]]", text)
    text = _LEADING_AYAH_RE.sub("", text, count=1)
    # al-Sa'di's "{64}" ayah-number markers: dropped at the start, kept as "(٦٤)" further on.
    text = re.sub(r"^\s*" + _AYAH_NUMBER_BRACES_RE.pattern, "", text, count=1)
    text = _AYAH_NUMBER_BRACES_RE.sub(lambda m: "(" + m.group(0).strip()[1:-1].strip().translate(_ARABIC_DIGITS) + ") ", text)
    # Ayah numbers inside a quote, "(30)", in Arabic digits like the rest of the app.
    text = _QUOTE_RE.sub(lambda q: _NUMBER_IN_QUOTE_RE.sub(lambda m: "(" + m.group(1).translate(_ARABIC_DIGITS) + ")", q.group(0)), text)
    if "{" not in text:
        text = _SPACED_PARENS_QUOTE_RE.sub(r"{\1}", text)
    return text.strip()


def load(db: Path, table: config.CenterTable, index: AyahIndex) -> list[RawEntry]:
    """One entry per ayah; consecutive ayahs with the very same text share an entry."""
    con = sqlite3.connect(f"file:{db.as_posix()}?mode=ro", uri=True)
    try:
        rows = con.execute(
            f'SELECT "{table.surah}", "{table.ayah}", "{table.text}" FROM "{table.table}" '
            f'ORDER BY "{table.surah}", "{table.ayah}"'
        ).fetchall()
    finally:
        con.close()
    entries: list[RawEntry] = []
    current: RawEntry | None = None
    current_raw = None  # repeats are spotted on the original text, before prepare()
    prev_ayah_id = None
    for surah, ayah, raw in rows:
        ayah_id = index.id(f"{int(surah)}:{int(ayah)}")
        if ayah_id is None:
            raise ValueError(f"{table.table}: unknown ayah {surah}:{ayah}")
        if is_placeholder(raw or ""):
            current, prev_ayah_id = None, ayah_id
            continue
        same_surah = prev_ayah_id is not None and index.key_of[prev_ayah_id][0] == int(surah)
        if current is not None and raw == current_raw and prev_ayah_id == ayah_id - 1 and same_surah:
            current.ayah_ids.append(ayah_id)
        elif current is not None and same_surah and prev_ayah_id == ayah_id - 1 and not _has_commentary(raw):
            # Only the ayah's own quote (or an empty <br>): the author explained it together with
            # the ayah before, whose entry quotes both (al-Baghawi 3:4-5, al-Tabari 26:15-17).
            current.ayah_ids.append(ayah_id)
        else:
            current, current_raw = RawEntry(prepare(raw), [ayah_id]), raw
            entries.append(current)
        prev_ayah_id = ayah_id
    return entries


def _has_commentary(raw: str) -> bool:
    """False when nothing is left once the quoted ayah and any tags are removed."""
    rest = re.sub(r"<[^>]+>", " ", prepare(raw))
    return re.search(r"[ء-ي]", rest) is not None
