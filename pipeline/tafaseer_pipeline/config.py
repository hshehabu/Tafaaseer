"""What goes into the app database and where it comes from."""

from dataclasses import dataclass
from pathlib import Path

PIPELINE_DIR = Path(__file__).resolve().parent.parent
CACHE_DIR = PIPELINE_DIR / "cache"
QUL_INPUT_DIR = PIPELINE_DIR / "input" / "qul"
DEFAULT_OUT = PIPELINE_DIR / "build" / "tafaseer.db"

TOTAL_AYAHS = 6236
TOTAL_SURAHS = 114

# Public mirror of the QUL / quran.com tafsir data (MIT-licensed repo). Pinned for reproducible builds.
MIRROR_COMMIT = "311a038bf532fa84566ca1bb2cdbeb210da3d5ed"
MIRROR_URL = "https://raw.githubusercontent.com/spa5k/tafsir_api/" + MIRROR_COMMIT + "/tafsir/{slug}/{surah}.json"

# KFGQPC Hafs text (matches the KFGQPC Hafs font) and a plain undiacritized copy, from the quran.com API.
QURAN_TEXT_URL = "https://api.quran.com/api/v4/quran/verses/qpc_hafs"
QURAN_SIMPLE_URL = "https://api.quran.com/api/v4/quran/verses/uthmani_simple"
# Surah names, revelation type, juz / hizb-quarter / page / sajda boundaries (CC BY, Tanzil.net).
TANZIL_METADATA_URL = "https://tanzil.net/res/text/metadata/quran-data.xml"
# Mushaf fonts, served by QUL's CDN, copied into the app by `font` (file name in the app -> URL):
# - the KFGQPC Uthmanic Script HAFS font (v18), which the qpc_hafs text is written for;
# - QUL's quran-common font: the ornate surah header frame and the calligraphic bismillah;
# - QUL's surah-name font (v4): each surah's name in calligraphy.
APP_FONTS_DIR = PIPELINE_DIR.parent / "app" / "assets" / "fonts"
MUSHAF_FONTS = {
    "UthmanicHafs.ttf": "https://static-cdn.tarteel.ai/qul/fonts/UthmanicHafs1Ver18.ttf",
    "QuranCommon.ttf": "https://static-cdn.tarteel.ai/qul/fonts/common/quran-common.ttf",
    "SurahNames.ttf": "https://static-cdn.tarteel.ai/qul/fonts/surah-names/v4/surah-name-v4.ttf",
}

# Tafsir Center for Quranic Studies (tafsir.net): one SQLite file with per-ayah editions of
# al-Sa'di, al-Baghawi, Ibn Kathir and al-Tabari, plus al-Mukhtasar. CC BY 4.0, credit required.
# About 234 MB, downloaded once into cache/ by the pipeline; nothing but the tafsir text reaches
# the app. Pinned to one dataset revision for reproducible builds.
CENTER_REVISION = "dbbfa77518a724a10e72d8d7fd48d2d36a50fa9e"
CENTER_URL = ("https://huggingface.co/datasets/tafsircenter/tafsir-mcp-data/resolve/"
              + CENTER_REVISION + "/quran.db")
CENTER_CREDIT = "Tafsir Center for Quranic Studies (https://tafsir.net), CC BY 4.0"

USER_AGENT = "tafaseer-pipeline/0.1"


@dataclass(frozen=True)
class CenterTable:
    """Where a tafsir lives in the Tafsir Center database."""
    table: str
    text: str = "tafsir"
    surah: str = "sura"
    ayah: str = "aya"


@dataclass(frozen=True)
class Tafsir:
    slug: str            # our id; also the file name for a manual QUL download in input/qul/
    qul_id: int          # resource id on qul.tarteel.ai/resources/tafsir/<id>; 0 when not on QUL
    mirror_slug: str     # folder name in the spa5k/tafsir_api mirror; "" when not on QUL
    name_ar: str
    short_name_ar: str   # label on the pill in the tafsir sheet
    author_ar: str
    died_hijri: int | None
    is_default: bool = False
    # The author comments on several ayahs at once and the source leaves the later ones empty.
    # When True, an ayah without text joins the commentary of the ayah before it (same surah).
    attach_gaps_to_previous: bool = False
    # Read from the Tafsir Center database instead of QUL. Its editions comment ayah by ayah,
    # where QUL's often keep one passage for several ayahs (al-Baghawi: 5,608 ayahs in shared
    # passages on QUL, 4 in the Tafsir Center edition).
    center: CenterTable | None = None


# Pill order in the app: al-Muyassar first (team decision E4), then shortest to longest.
# Sources (decided 25 Nov 2026): al-Muyassar stays on QUL (a revised edition with surah
# introductions and ﴿﴾-marked quotes; the Tafsir Center copy is the older edition), al-Qurtubi
# stays on QUL (not in the Tafsir Center database); the rest come from the Tafsir Center.
TAFSIRS: list[Tafsir] = [
    Tafsir("muyassar", 38, "ar-tafsir-muyassar", "التفسير الميسر", "الميسر",
           "نخبة من العلماء (مجمع الملك فهد)", None, is_default=True),
    Tafsir("mukhtasar", 0, "", "المختصر في التفسير", "المختصر",
           "نخبة من العلماء (مركز تفسير للدراسات القرآنية)", None,
           center=CenterTable("QuranTafseer", text="Mukhtasarar", surah="surahNo", ayah="ayahNo")),
    Tafsir("saadi", 24, "ar-tafseer-al-saddi", "تيسير الكريم الرحمن في تفسير كلام المنان", "السعدي",
           "عبد الرحمن بن ناصر السعدي", 1376, attach_gaps_to_previous=True,
           center=CenterTable("tafsir_saadi")),
    Tafsir("baghawi", 27, "ar-tafsir-al-baghawi", "معالم التنزيل", "البغوي",
           "الحسين بن مسعود البغوي", 516, center=CenterTable("tafsir_baghawy")),
    Tafsir("ibn-kathir", 22, "ar-tafsir-ibn-kathir", "تفسير القرآن العظيم", "ابن كثير",
           "إسماعيل بن عمر بن كثير", 774, center=CenterTable("tafsir_katheer")),
    Tafsir("qurtubi", 23, "ar-tafseer-al-qurtubi", "الجامع لأحكام القرآن", "القرطبي",
           "محمد بن أحمد القرطبي", 671),
    Tafsir("tabari", 37, "ar-tafsir-al-tabari", "جامع البيان عن تأويل آي القرآن", "الطبري",
           "محمد بن جرير الطبري", 310, center=CenterTable("tafsir_tabary")),
]

TAFSIR_BY_SLUG = {t.slug: t for t in TAFSIRS}
