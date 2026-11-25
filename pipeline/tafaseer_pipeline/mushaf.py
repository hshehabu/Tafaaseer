"""Madani mushaf page layout: 604 pages, 15 lines, every word placed on its line.

The word list and each word's page and line come from the quran.com API v4 (Madani 15-line layout).
The API only places words, so the lines without words are filled in here: before each surah comes a
surah-title line, then a bismillah line (except surahs 1 and 9, where 1:1 is the bismillah itself and
9 has none). The app draws the words with the KFGQPC Hafs font.
"""

import json
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

from . import config
from .sources import _download

PAGES = 604
LINES_PER_PAGE = 15
PAGE_URL = ("https://api.quran.com/api/v4/verses/by_page/{page}?words=true&per_page=50&page={n}"
            "&fields=verse_key&word_fields=text_qpc_hafs,line_number,page_number")


@dataclass(frozen=True)
class Word:
    id: int          # 1.. in mushaf order
    ayah_id: int
    page: int
    line: int
    is_end: bool     # the end-of-ayah number
    text: str


@dataclass(frozen=True)
class Line:
    page: int
    line: int
    kind: str        # "ayah" | "surah" | "basmala"
    surah: int       # for "surah" and "basmala" lines; 0 for ayah lines
    first_word: int  # for "ayah" lines; 0 otherwise
    last_word: int


def page_files(workers: int = 8) -> dict[int, list[Path]]:
    """Downloads each page's API responses (one per 50 verses) into the cache."""
    base = config.CACHE_DIR / "mushaf" / "quran-com-v4"

    def fetch(page: int) -> tuple[int, list[Path]]:
        files, n = [], 1
        while True:
            path = _download(PAGE_URL.format(page=page, n=n), base / f"p{page:03d}-{n}.json")
            data = json.loads(path.read_text(encoding="utf-8"))
            files.append(path)
            if not data.get("pagination", {}).get("next_page"):
                return page, files
            n += 1

    if not (base / f"p{PAGES:03d}-1.json").exists():
        print("  downloading the mushaf page layout (604 pages) ...", file=sys.stderr)
    with ThreadPoolExecutor(max_workers=workers) as pool:
        return dict(pool.map(fetch, range(1, PAGES + 1)))


def load_words(files: dict[int, list[Path]], ayah_id_of: dict[str, int]) -> list[Word]:
    seen: dict[int, Word] = {}
    order: list[tuple[int, int, int]] = []
    for page in sorted(files):
        for path in files[page]:
            for verse in json.loads(path.read_text(encoding="utf-8"))["verses"]:
                ayah_id = ayah_id_of[verse["verse_key"]]
                for w in verse["words"]:
                    if w["id"] in seen:  # an ayah that crosses a page is returned with both pages
                        continue
                    if w["char_type_name"] not in ("word", "end"):
                        raise ValueError(f"page {page}: unexpected word type {w['char_type_name']!r}")
                    seen[w["id"]] = Word(0, ayah_id, w["page_number"], w["line_number"],
                                         w["char_type_name"] == "end", w["text_qpc_hafs"])
                    order.append((ayah_id, w["position"], w["id"]))
    order.sort()
    # The API's page_number is sometimes one too low for the first ayah of a page, but its line numbers
    # are right. So the page is counted instead: in mushaf order, a line number that goes down means
    # a new page. (A page starts on line 1-3 and the page before always ends far below that.)
    out: list[Word] = []
    page, prev_line = 1, 0
    for i, (_, _, wid) in enumerate(order, start=1):
        w = seen[wid]
        if w.line < prev_line:
            page += 1
        prev_line = w.line
        out.append(Word(i, w.ayah_id, page, w.line, w.is_end, w.text))
    if page != PAGES:
        raise ValueError(f"counted {page} mushaf pages, expected {PAGES}")
    return out


def build_lines(words: list[Word], surah_first_ayah: dict[int, int]) -> list[Line]:
    """Groups words into lines and fills the empty lines with surah titles and bismillahs."""
    by_slot: dict[tuple[int, int], list[Word]] = {}
    for w in words:
        by_slot.setdefault((w.page, w.line), []).append(w)

    pages = words[-1].page
    last_line = {p: LINES_PER_PAGE for p in range(1, pages + 1)}
    for p in (1, 2):  # the two opening pages are short
        last_line[p] = max(line for (page, line) in by_slot if page == p)
    slots = [(p, n) for p in range(1, pages + 1) for n in range(1, last_line[p] + 1)]

    starts = {first: s for s, first in surah_first_ayah.items()}  # ayah id -> surah starting there
    lines: dict[tuple[int, int], Line] = {}
    pending: list[tuple[int, int]] = []  # empty slots waiting for the next surah start
    for slot in slots:
        ws = by_slot.get(slot)
        if not ws:
            pending.append(slot)
            continue
        first = ws[0]
        starts_ayah = first.id == 1 or words[first.id - 2].ayah_id != first.ayah_id
        surah = starts.get(first.ayah_id) if starts_ayah else None
        if surah is not None:
            kinds = ["surah"] if surah in (1, 9) else ["surah", "basmala"]
            if len(pending) != len(kinds):
                raise ValueError(f"surah {surah}: {len(pending)} empty lines before it, expected {len(kinds)}")
            for (p, n), kind in zip(pending, kinds):
                lines[(p, n)] = Line(p, n, kind, surah, 0, 0)
            pending = []
        elif pending:
            raise ValueError(f"empty lines {pending} are not followed by a surah start")
        lines[slot] = Line(slot[0], slot[1], "ayah", 0, ws[0].id, ws[-1].id)
    if pending:
        raise ValueError(f"empty lines at the end of the mushaf: {pending}")
    return [lines[s] for s in slots]


def check(words: list[Word], lines: list[Line], ayah_text: dict[int, str]) -> list[str]:
    """Problems that would make a page wrong."""
    problems = []
    joined: dict[int, list[str]] = {}
    for w in words:
        joined.setdefault(w.ayah_id, []).append(w.text)
    for ayah_id, text in ayah_text.items():
        # Spacing differs in a few places: a split joined word, the sajda mark as its own word, and a
        # no-break space after the hizb mark ۞ in the ayah text where the word has a plain space.
        got = "".join(" ".join(joined.get(ayah_id, [])).split())
        if got != "".join(text.split()):
            problems.append(f"ayah {ayah_id}: words don't match the ayah text")
    surah_lines = sum(1 for line in lines if line.kind == "surah")
    if surah_lines != config.TOTAL_SURAHS:
        problems.append(f"{surah_lines} surah title lines, expected {config.TOTAL_SURAHS}")
    basmalas = sum(1 for line in lines if line.kind == "basmala")
    if basmalas != config.TOTAL_SURAHS - 2:
        problems.append(f"{basmalas} bismillah lines, expected {config.TOTAL_SURAHS - 2}")
    return problems[:20]
