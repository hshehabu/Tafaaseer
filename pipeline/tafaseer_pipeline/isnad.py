"""Find chains of narrators (isnad) so the app can collapse them.

This is a heuristic. A chain is a run of transmission words (حدثنا، أخبرنا، عن ...)
separated by short name segments. We hide everything from the first link up to the
start of the last link, so the final narrator stays visible:

    حدثنا ابن حميد، قال: ثنا سلمة، عن ابن إسحاق، عن ابن عباس قال: ...
    [-------------- hidden --------------------]عن ابن عباس قال: ...

The app shows the hidden part as a tappable marker, so a wrong guess costs one tap,
but hiding real content is worse than missing a chain. Every rule below therefore
errs on the side of stopping the chain early.
"""

import re

from .arabic import fold_for_matching

# Folded forms (no diacritics, alef forms folded to ا).
START_TOKENS = {"حدثنا", "حدثني", "حدثناه", "حدثنيه", "اخبرنا", "اخبرني", "اخبرناه", "انبانا", "انباني",
                "ثنا", "ثني"}
# Links that continue a chain but never start one: "عن" and the abbreviations "أنا"/"نا" (for أخبرنا)
# are ordinary words elsewhere.
LINK_TOKENS = START_TOKENS | {"عن", "سمعت", "انا", "نا"}

_TOKEN_RE = re.compile(
    r"(?<!\w)و?(" + "|".join(sorted(LINK_TOKENS, key=len, reverse=True)) + r")(?!\w)"
)

MAX_GAP_CHARS = 100  # longest name segment allowed between two links
MAX_GAP_WORDS = 12
MIN_HIDDEN_CHARS = 12

# A standalone word in a gap that means the narrated text (matn) has started.
_MATN_WORDS = {"ان", "انه", "انها", "انهم", "يقول", "فقال", "قالت", "لما", "اذا", "اي"}
_FILLER_WORDS = {"قال", "قالا", "قالوا", "يعني", "-", "–", ""}
_PROPHET_RE = re.compile(r"^[\s،,:]*(النبي|رسول الله)")
_SHADDA = "ّ"


def _abbreviation_ok(original: str) -> bool:
    """"أَنَا" (for أخبرنا) is a link; "إِنَّا" / "أَنَّا" (indeed we / that we) and "وَأَنَا" (and I) are not."""
    return not original.startswith(("إ", "و")) and _SHADDA not in original


def _gap_ok(gap: str) -> bool:
    if len(gap) > MAX_GAP_CHARS or "\n" in gap:
        return False
    if any(ch in gap for ch in "﴿{[\"«"):
        return False
    if any(ch.isdigit() for ch in gap):
        return False
    if _PROPHET_RE.match(gap):
        # "حدثنا رسول الله ﷺ ..." : the Prophet is the source, so what follows is the matn.
        return False
    words = gap.replace("،", " ").replace(",", " ").replace(":", " ").split()
    if len(words) > MAX_GAP_WORDS:
        return False
    if any(w in _MATN_WORDS for w in words):
        return False
    if not any(w not in _FILLER_WORDS for w in words):
        # Two links need a narrator's name between them ("أخبرني عن الوضوء" has none).
        return False
    if ":" in gap and gap.rsplit(":", 1)[1].strip("  -–"):
        # "قال: ثنا" continues the chain; "قال: قال المشركون" means the matn began.
        return False
    return True


def find_isnads(text: str, blocked: list[tuple[int, int]] | None = None) -> list[tuple[int, int]]:
    """Return (start, end) ranges of `text` to hide, in order and non-overlapping.

    `blocked` holds ranges (such as Quran quotes) that a chain may not start in or cross.
    """
    blocked = blocked or []
    folded, index = fold_for_matching(text)
    if not folded:
        return []

    def orig(i: int) -> int:
        return index[i] if i < len(index) else len(text)

    def is_blocked(start: int, end: int) -> bool:
        return any(start < b_end and b_start < end for b_start, b_end in blocked)

    # (start including a glued و, end, bare token)
    tokens = [
        (m.start(0), m.end(1), m.group(1)) for m in _TOKEN_RE.finditer(folded)
        if m.group(1) not in ("انا", "نا") or _abbreviation_ok(text[orig(m.start(0)):orig(m.end(1) - 1) + 1])
    ]
    found: list[tuple[int, int]] = []
    i = 0
    while i < len(tokens):
        start, end, word = tokens[i]
        if word not in START_TOKENS or is_blocked(orig(start), orig(end - 1) + 1):
            i += 1
            continue
        chain = [tokens[i]]
        j = i + 1
        while j < len(tokens):
            prev_end = chain[-1][1]
            nxt = tokens[j]
            if not _gap_ok(folded[prev_end:nxt[0]]) or is_blocked(orig(prev_end), orig(nxt[0])):
                break
            chain.append(nxt)
            j += 1
        if len(chain) < 2:
            i += 1
            continue
        last = chain[-1]
        # "عن أبي هريرة، عن النبي ﷺ" keeps the Companion visible, not just "عن النبي".
        if len(chain) >= 3 and _PROPHET_RE.match(folded[last[1]:last[1] + 20]):
            last = chain[-2]
        hide_start, hide_end = orig(chain[0][0]), orig(last[0])
        if last[0] - chain[0][0] >= MIN_HIDDEN_CHARS:  # measured without diacritics
            found.append((hide_start, hide_end))
        i = j
    return found
