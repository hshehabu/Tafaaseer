"""Read raw tafsir data into entries: one text plus the ayahs it covers.

Three input formats:
- mirror:      spa5k/tafsir_api per-surah files, [{"surah", "ayah", "text"}, ...]. Shared
               commentary is repeated on each ayah, so consecutive identical texts form one entry.
- qul-json:    QUL JSON export, {"2:3": {"text": ..., "ayah_keys": [...]}, "2:4": "2:3", ...}.
               A string value points to the ayah key that holds the shared text.
- qul-sqlite:  QUL SQLite export. The exact columns are not documented publicly, so the
               loader looks for an ayah-key column, a text column and optional grouping columns.
"""

import json
import re
import sqlite3
from dataclasses import dataclass, field
from pathlib import Path


_PLACEHOLDER_RE = re.compile(r"[\s×*\-ـ.]*")


def is_placeholder(text: str) -> bool:
    """True for empty text or a stand-in like "×" that means "covered with another ayah"."""
    return _PLACEHOLDER_RE.fullmatch(text or "") is not None


def attach_gaps_to_neighbours(entries: list["RawEntry"], index: "AyahIndex") -> int:
    """Give each ayah without text to the entry before it in the same surah (or after it, at a
    surah's start). Returns how many ayahs were attached."""
    owner: dict[int, RawEntry] = {a: e for e in entries for a in e.ayah_ids}
    attached = 0
    for ayah_id in range(1, index.total + 1):
        prev = owner.get(ayah_id - 1)
        if ayah_id not in owner and prev and index.key_of[ayah_id - 1][0] == index.key_of[ayah_id][0]:
            prev.ayah_ids.append(ayah_id)
            owner[ayah_id] = prev
            attached += 1
    for ayah_id in range(index.total, 0, -1):
        nxt = owner.get(ayah_id + 1)
        if ayah_id not in owner and nxt and index.key_of[ayah_id + 1][0] == index.key_of[ayah_id][0]:
            nxt.ayah_ids.insert(0, ayah_id)
            owner[ayah_id] = nxt
            attached += 1
    for e in entries:
        e.ayah_ids.sort()
    return attached


@dataclass
class RawEntry:
    text: str
    ayah_ids: list[int] = field(default_factory=list)


class AyahIndex:
    """Maps "surah:ayah" keys and (surah, ayah) pairs to ayah ids 1..6236."""

    def __init__(self, surah_ayah_counts: list[int]):
        self.by_key: dict[str, int] = {}
        self.key_of: dict[int, tuple[int, int]] = {}
        ayah_id = 0
        for surah, count in enumerate(surah_ayah_counts, start=1):
            for ayah in range(1, count + 1):
                ayah_id += 1
                self.by_key[f"{surah}:{ayah}"] = ayah_id
                self.key_of[ayah_id] = (surah, ayah)
        self.total = ayah_id

    def id(self, key: str) -> int | None:
        return self.by_key.get(str(key).strip())


def load_mirror(files_by_surah: dict[int, Path], index: AyahIndex) -> list[RawEntry]:
    entries: list[RawEntry] = []
    for surah in sorted(files_by_surah):
        rows = json.loads(files_by_surah[surah].read_text(encoding="utf-8"))
        rows = sorted(rows, key=lambda r: int(r["ayah"]))
        current: RawEntry | None = None
        prev_ayah_id = None
        for row in rows:
            ayah_id = index.id(f"{int(row['surah'])}:{int(row['ayah'])}")
            if ayah_id is None:
                raise ValueError(f"mirror surah {surah}: unknown ayah {row['surah']}:{row['ayah']}")
            text = (row.get("text") or "").strip()
            if is_placeholder(text):
                current, prev_ayah_id = None, ayah_id
                continue
            if current is not None and text == current.text and prev_ayah_id == ayah_id - 1:
                current.ayah_ids.append(ayah_id)
            else:
                current = RawEntry(text, [ayah_id])
                entries.append(current)
            prev_ayah_id = ayah_id
    return entries


def load_qul_json(path: Path, index: AyahIndex) -> list[RawEntry]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, list):  # tolerate a list of {"ayah_key": ..., ...} records
        data = {str(r.get("ayah_key") or r.get("verse_key")): r for r in data}
    entries: dict[str, RawEntry] = {}
    pointers: dict[str, str] = {}
    for key, value in data.items():
        if isinstance(value, str):
            pointers[key] = value
        elif isinstance(value, dict):
            text = (value.get("text") or "").strip()
            keys = value.get("ayah_keys") or [key]
            if isinstance(keys, str):
                keys = _split_keys(keys)
            if not is_placeholder(text):
                ids = sorted({i for i in (index.id(k) for k in keys) if i is not None})
                entries[key] = RawEntry(text, ids)
    _attach_pointers(entries, pointers, index)
    return list(entries.values())


def load_qul_sqlite(path: Path, index: AyahIndex) -> list[RawEntry]:
    con = sqlite3.connect(f"file:{path.as_posix()}?mode=ro", uri=True)
    try:
        table, cols = _find_tafsir_table(con)
        key_col = next(c for c in ("ayah_key", "verse_key") if c in cols)
        text_col = "text" if "text" in cols else next(c for c in cols if "text" in c)
        group_col = next((c for c in ("group_ayah_key", "group_verse_key") if c in cols), None)
        keys_col = next((c for c in ("ayah_keys", "verse_keys") if c in cols), None)
        range_cols = ("from_ayah", "to_ayah") if {"from_ayah", "to_ayah"} <= set(cols) else None
        select = [key_col, text_col] + [c for c in (group_col, keys_col) if c] + list(range_cols or ())
        rows = con.execute(f'SELECT {", ".join(_q(c) for c in select)} FROM {_q(table)}').fetchall()
    finally:
        con.close()

    entries: dict[str, RawEntry] = {}
    pointers: dict[str, str] = {}
    for row in rows:
        rec = dict(zip(select, row))
        key = str(rec[key_col]).strip()
        text = (rec[text_col] or "").strip()
        group = str(rec[group_col]).strip() if group_col and rec[group_col] else None
        if is_placeholder(text):
            if group and group != key:
                pointers[key] = group
            continue
        keys = [key]
        if keys_col and rec[keys_col]:
            keys = _split_keys(rec[keys_col])
        elif range_cols and rec["from_ayah"] and rec["to_ayah"]:
            first, last = index.id(str(rec["from_ayah"])), index.id(str(rec["to_ayah"]))
            if first and last:
                keys = [f"{s}:{a}" for s, a in (index.key_of[i] for i in range(first, last + 1))]
        ids = sorted({i for i in (index.id(k) for k in keys) if i is not None})
        entries[group or key] = RawEntry(text, ids or [index.id(key)])
        if group and group != key:
            pointers[key] = group
    _attach_pointers(entries, pointers, index)
    return list(entries.values())


def _attach_pointers(entries: dict[str, RawEntry], pointers: dict[str, str], index: AyahIndex) -> None:
    for key, target in pointers.items():
        seen = set()
        while target in pointers and target not in entries and target not in seen:
            seen.add(target)
            target = pointers[target]
        entry = entries.get(target)
        ayah_id = index.id(key)
        if entry is not None and ayah_id is not None and ayah_id not in entry.ayah_ids:
            entry.ayah_ids.append(ayah_id)
            entry.ayah_ids.sort()


def _split_keys(value) -> list[str]:
    if isinstance(value, list):
        return [str(v) for v in value]
    value = str(value).strip()
    if value.startswith("["):
        try:
            return [str(v) for v in json.loads(value)]
        except json.JSONDecodeError:
            pass
    return [k for k in re.split(r"[,\s]+", value) if k]


def _find_tafsir_table(con: sqlite3.Connection) -> tuple[str, list[str]]:
    tables = [r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")]
    for table in tables:
        cols = [r[1] for r in con.execute(f"PRAGMA table_info({_q(table)})")]
        if any(c in cols for c in ("ayah_key", "verse_key")) and any("text" in c for c in cols):
            return table, cols
    raise ValueError(f"no table with an ayah key and a text column (tables: {tables})")


def _q(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'
