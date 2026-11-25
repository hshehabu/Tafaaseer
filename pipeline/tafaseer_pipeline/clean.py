"""Turn one raw tafsir entry into structured, readable paragraphs.

Output shape (stored as compressed JSON in tafsir_entries.body):

    {"v": 1, "p": [{"k": "p", "s": [[0, "text"], [1, "quran"], [3, "note"]]}, ...]}

Paragraph kinds ("k"):
    p     normal paragraph
    h     heading (e.g. "القول في تأويل قوله ..." or a short title line)
    poem  a line of poetry; hemistichs are separated by "..."
    hr    a divider (lines made only of * or ×)
    ed    an editor's note standing on its own (its NOTE spans are shown, in a muted style)

Span types (first item of each span):
    0 TEXT    plain text
    1 QURAN   a Quran quote, without its ﴿﴾ or {} delimiters (the app adds ﴿ ﴾)
    2 ISNAD   a chain of narrators the app can collapse
    3 NOTE    an editor footnote, shown behind a small tap-to-show marker
    4 REF     a sura/ayah reference such as [البقرة: ٢٨١]
"""

import html
import re

from .arabic import ARABIC_LETTERS, fold_for_matching, word_count
from .isnad import find_isnads

TEXT, QURAN, ISNAD, NOTE, REF = 0, 1, 2, 3, 4
NOTE_MARK = ""  # placeholder for an extracted footnote while segmenting

_NOTE_RE = re.compile(r"\[\[(.*?)\]\]", re.S)
_QURAN_RE = re.compile(r"﴿([^﴾]{1,6000})﴾|\{([^{}\n]{1,3000})\}")
_REF_RE = re.compile(
    r"\[(?:سورة\s+)?[" + ARABIC_LETTERS + r"ً-ْ ]{2,30}:\s*"
    r"[0-9٠-٩][0-9٠-٩\s\-–،,و]*\]"
)
_TAG_RE = re.compile(r"<\s*(/?)\s*([a-zA-Z0-9]+)[^>]*>")
_BLOCK_TAGS = {"p", "br", "div", "li", "h1", "h2", "h3", "h4", "h5", "h6", "tr"}
_INVISIBLE_RE = re.compile("[​‎‏‪-‮⁦-⁩﻿]")
_TATWEEL_IN_WORD_RE = re.compile("(?<=[" + ARABIC_LETTERS + "])ـ+(?=[" + ARABIC_LETTERS + "ً-ْ])")
_AR = "[" + ARABIC_LETTERS + "ً-ْٰ]"
_TERMINATED_RE = re.compile(r"[.:؟!»\"﴾)\]}،؛…\-*]\s*$")
_HR_RE = re.compile(r"[\s*×\-ـ•]+")
_LABEL_RE = re.compile(r"\[([^\[\]:0-9٠-٩]{2,40})\]")  # e.g. "[التفسير]"
# Manuscript folio markers such as "٦/أ" or "[١٢/ب]".
_FOLIO_RE = re.compile(r"\s?\[?[0-9٠-٩]{1,4}\s?/\s?[أبا]\]?(?=\s|[" + ARABIC_LETTERS + r"]|$)")


def html_to_text(text: str) -> str:
    """Strip HTML tags (QUL exports contain <p>, <h2>, <b> ...), keeping block breaks as newlines.

    Raw newlines inside HTML are insignificant (QUL text is hard-wrapped inside <p>), so they
    become spaces; only block tags start a new paragraph.
    """
    if "<" in text and _TAG_RE.search(text):
        text = re.sub(r"\s*\n\s*", " ", text)
        text = _TAG_RE.sub(lambda m: "\n" if m.group(2).lower() in _BLOCK_TAGS else "", text)
    if "&" in text:
        text = html.unescape(text)
    return text


def normalize(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n").replace(" ", " ")
    text = _INVISIBLE_RE.sub("", text)
    text = _TATWEEL_IN_WORD_RE.sub("", text)
    text = _FOLIO_RE.sub(" ", text)
    # Latin punctuation inside Arabic text -> Arabic punctuation (common in al-Sa'di).
    text = re.sub(r"(?<=" + _AR + r")\s*,\s*", "، ", text)
    text = re.sub(r"(?<=" + _AR + r")\s*;\s*", "؛ ", text)
    text = re.sub(r"(?<=" + _AR + r")\s*\?", "؟", text)
    # No space before Arabic punctuation, one space after it.
    text = re.sub(r"[ \t]+([،؛؟])", r"\1", text)
    text = re.sub(r"([،؛])(?=" + _AR + ")", r"\1 ", text)
    text = re.sub(r"[ \t]{2,}", " ", text)
    return text


def _extract_notes(text: str) -> tuple[str, list[str]]:
    notes: list[str] = []

    def repl(m: re.Match) -> str:
        note = " ".join(m.group(1).split())
        if not note:
            return ""
        notes.append(note)
        return NOTE_MARK

    return _NOTE_RE.sub(repl, text), notes


def _classify(line: str) -> str:
    plain = line.replace(NOTE_MARK, "").strip()
    if not plain or _HR_RE.fullmatch(plain):
        return "hr"
    folded, _ = fold_for_matching(plain)
    if folded.startswith("القول في تاويل") and len(plain) <= 700:
        return "h"
    if (" ... " in plain or "…" in plain) and len(plain) <= 260:
        return "poem"
    if plain.endswith("*") and len(plain) <= 160:
        return "poem"
    if len(plain) <= 60 and not _TERMINATED_RE.search(plain):
        return "h"
    if _LABEL_RE.fullmatch(plain):
        return "h"
    return "p"


def _segment(line: str, notes: list[str], note_pos: list[int]) -> list[list]:
    """Split one line into typed spans. `note_pos[0]` is the next unused note index."""
    intervals: list[tuple[int, int, int, str]] = []  # (start, end, type, inner text)
    for m in _QURAN_RE.finditer(line):
        inner = m.group(1) if m.group(1) is not None else m.group(2)
        if inner.strip() and not inner.strip().isdigit():
            intervals.append((m.start(), m.end(), QURAN, inner.strip()))
    quran = [(s, e) for s, e, _, _ in intervals]

    def overlaps(s: int, e: int) -> bool:
        return any(s < ie and is_ < e for is_, ie, _, _ in intervals)

    for m in _REF_RE.finditer(line):
        if not overlaps(m.start(), m.end()):
            intervals.append((m.start(), m.end(), REF, m.group(0)))
    for s, e in find_isnads(line, blocked=quran):
        if not overlaps(s, e):
            intervals.append((s, e, ISNAD, line[s:e]))
    intervals.sort()

    spans: list[list] = []

    def emit(kind: int, chunk: str) -> None:
        parts = chunk.split(NOTE_MARK)
        for k, part in enumerate(parts):
            if k > 0:
                if note_pos[0] < len(notes):
                    spans.append([NOTE, notes[note_pos[0]]])
                note_pos[0] += 1
            if part:
                if spans and spans[-1][0] == kind and kind in (TEXT, ISNAD):
                    spans[-1][1] += part
                else:
                    spans.append([kind, part])

    pos = 0
    for start, end, kind, inner in intervals:
        if start > pos:
            emit(TEXT, line[pos:start])
        emit(kind, inner)
        pos = end
    if pos < len(line):
        emit(TEXT, line[pos:])

    # Trim the outer whitespace of the paragraph only.
    if spans and spans[0][0] in (TEXT, ISNAD):
        spans[0][1] = spans[0][1].lstrip()
    if spans and spans[-1][0] in (TEXT, ISNAD):
        spans[-1][1] = spans[-1][1].rstrip()
    return [s for s in spans if s[1]]


def clean_entry(raw: str) -> dict:
    """Clean one tafsir entry. Returns {"v": 1, "p": [...]} plus stats under "_stats"."""
    text = normalize(html_to_text(raw))
    text, notes = _extract_notes(text)
    note_pos = [0]
    paragraphs: list[dict] = []
    for line in text.split("\n"):
        line = line.strip()
        if not line:
            continue
        line = line.lstrip("⁕").strip()
        line = re.sub(r":\s*-\s*$", ":", line)  # al-Tabari's "الذي:-"
        if NOTE_MARK in line and not line.replace(NOTE_MARK, "").strip():
            # A line that is only an editor's note (e.g. "the author did not comment on this ayah").
            spans = []
            for _ in range(line.count(NOTE_MARK)):
                if note_pos[0] < len(notes):
                    spans.append([NOTE, notes[note_pos[0]]])
                note_pos[0] += 1
            if spans:
                paragraphs.append({"k": "ed", "s": spans})
            continue
        kind = _classify(line)
        if kind == "hr":
            # Keep any footnote attached to a divider line by moving it onto the previous paragraph.
            for _ in range(line.count(NOTE_MARK)):
                if paragraphs and note_pos[0] < len(notes):
                    paragraphs[-1]["s"].append([NOTE, notes[note_pos[0]]])
                note_pos[0] += 1
            if paragraphs and paragraphs[-1]["k"] != "hr":
                paragraphs.append({"k": "hr", "s": []})
            continue
        label = _LABEL_RE.fullmatch(line)
        if kind == "h" and label:
            line = label.group(1).strip()
        spans = _segment(line, notes, note_pos)
        if spans:
            paragraphs.append({"k": kind, "s": spans})
    while paragraphs and paragraphs[-1]["k"] == "hr":
        paragraphs.pop()

    # Footnotes are hidden behind markers, so they don't count, except a standalone editor's note.
    words = sum(word_count(s[1]) for p in paragraphs for s in p["s"] if s[0] != NOTE or p["k"] == "ed")
    isnad_words = sum(word_count(s[1]) for p in paragraphs for s in p["s"] if s[0] == ISNAD)
    return {
        "v": 1,
        "p": paragraphs,
        "_stats": {
            "words": words,
            "words_without_isnad": words - isnad_words,
            "notes": len(notes),
            "notes_placed": min(note_pos[0], len(notes)),
            "isnads": sum(1 for p in paragraphs for s in p["s"] if s[0] == ISNAD),
            "unclosed_brackets": text.count("[[") + text.count("]]"),
        },
    }
