"""Small Arabic text helpers."""

import re

# Harakat, Quranic annotation marks, superscript alef and tatweel.
_DIACRITIC_CLASS = "ؐ-ًؚ-ٰٟۖ-ۜ۟-۪ۨ-ۭـ"
DIACRITICS_RE = re.compile("[" + _DIACRITIC_CLASS + "]")

ARABIC_LETTERS = "ء-غف-يٱ-ۓ"

# One-to-one letter folds used only for matching (keeps string length, so indexes still line up).
_FOLD = str.maketrans({"أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا"})


def strip_diacritics(text: str) -> str:
    return DIACRITICS_RE.sub("", text)


def fold_for_matching(text: str) -> tuple[str, list[int]]:
    """Remove diacritics and fold alef forms.

    Returns the folded string and, for each of its characters, the index of the
    same character in the original string.
    """
    out: list[str] = []
    index: list[int] = []
    for i, ch in enumerate(text):
        if DIACRITICS_RE.match(ch):
            continue
        out.append(ch)
        index.append(i)
    return "".join(out).translate(_FOLD), index


def word_count(text: str) -> int:
    return len(text.split())
