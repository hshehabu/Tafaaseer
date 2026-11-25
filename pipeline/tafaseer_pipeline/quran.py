"""Quran text and structure: surahs, ayahs, juz, hizb, rub, page, sajda."""

import bisect
import json
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path

from . import config


@dataclass
class Surah:
    id: int
    name_ar: str
    name_translit: str
    revelation: str  # "meccan" | "medinan"
    ayah_count: int
    first_ayah_id: int


@dataclass
class Ayah:
    id: int
    surah: int
    ayah: int
    text: str
    text_simple: str
    juz: int
    hizb: int
    rub: int
    page: int
    sajda: bool


def _starts(root: ET.Element, group: str, item: str, first_ayah: dict[int, int]) -> list[int]:
    """Ayah ids where each juz / quarter / page begins, in order."""
    node = root.find(group)
    if node is None:
        raise ValueError(f"Tanzil metadata has no <{group}>")
    return [first_ayah[int(e.get("sura"))] + int(e.get("aya")) - 1 for e in node.findall(item)]


def _segment_number(starts: list[int], ayah_id: int) -> int:
    return bisect.bisect_right(starts, ayah_id)


def load(files: dict[str, Path]) -> tuple[list[Surah], list[Ayah]]:
    root = ET.parse(files["metadata"]).getroot()
    surahs: list[Surah] = []
    for e in root.find("suras").findall("sura"):
        surahs.append(Surah(
            id=int(e.get("index")),
            name_ar=e.get("name"),
            name_translit=e.get("tname"),
            revelation="meccan" if e.get("type") == "Meccan" else "medinan",
            ayah_count=int(e.get("ayas")),
            first_ayah_id=int(e.get("start")) + 1,
        ))
    first_ayah = {s.id: s.first_ayah_id for s in surahs}
    juz_starts = _starts(root, "juzs", "juz", first_ayah)
    rub_starts = _starts(root, "hizbs", "quarter", first_ayah)
    page_starts = _starts(root, "pages", "page", first_ayah)
    sajdas = set(_starts(root, "sajdas", "sajda", first_ayah))

    text = {v["verse_key"]: v["text_qpc_hafs"] for v in json.loads(files["text"].read_text(encoding="utf-8"))["verses"]}
    simple = {v["verse_key"]: v["text_uthmani_simple"]
              for v in json.loads(files["simple"].read_text(encoding="utf-8"))["verses"]}

    ayahs: list[Ayah] = []
    for s in surahs:
        for n in range(1, s.ayah_count + 1):
            key = f"{s.id}:{n}"
            ayah_id = s.first_ayah_id + n - 1
            if key not in text or key not in simple:
                raise ValueError(f"Quran text is missing {key}")
            rub = _segment_number(rub_starts, ayah_id)
            ayahs.append(Ayah(
                id=ayah_id, surah=s.id, ayah=n, text=text[key].strip(), text_simple=simple[key].strip(),
                juz=_segment_number(juz_starts, ayah_id), hizb=(rub - 1) // 4 + 1, rub=rub,
                page=_segment_number(page_starts, ayah_id), sajda=ayah_id in sajdas,
            ))

    problems = []
    if len(surahs) != config.TOTAL_SURAHS:
        problems.append(f"{len(surahs)} surahs, expected {config.TOTAL_SURAHS}")
    if len(ayahs) != config.TOTAL_AYAHS:
        problems.append(f"{len(ayahs)} ayahs, expected {config.TOTAL_AYAHS}")
    if len(text) != config.TOTAL_AYAHS:
        problems.append(f"Quran text has {len(text)} ayahs, expected {config.TOTAL_AYAHS}")
    if ayahs and (ayahs[-1].juz, ayahs[-1].hizb, ayahs[-1].page) != (30, 60, 604):
        problems.append(f"last ayah is juz {ayahs[-1].juz}, hizb {ayahs[-1].hizb}, page {ayahs[-1].page}")
    if problems:
        raise ValueError("Quran data check failed: " + "; ".join(problems))
    return surahs, ayahs
