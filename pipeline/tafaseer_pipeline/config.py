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

USER_AGENT = "tafaseer-pipeline/0.1"


@dataclass(frozen=True)
class Tafsir:
    slug: str            # our id; also the file name for a manual QUL download in input/qul/
    qul_id: int          # resource id on qul.tarteel.ai/resources/tafsir/<id>
    mirror_slug: str     # folder name in the spa5k/tafsir_api mirror
    name_ar: str
    short_name_ar: str   # label on the pill in the tafsir sheet
    author_ar: str
    died_hijri: int | None
    is_default: bool = False
    # The author comments on several ayahs at once and the source leaves the later ones empty.
    # When True, an ayah without text joins the commentary of the ayah before it (same surah).
    attach_gaps_to_previous: bool = False


# Pill order in the app: al-Muyassar first (team decision E4), then shortest to longest.
TAFSIRS: list[Tafsir] = [
    Tafsir("muyassar", 38, "ar-tafsir-muyassar", "التفسير الميسر", "الميسر",
           "نخبة من العلماء (مجمع الملك فهد)", None, is_default=True),
    Tafsir("saadi", 24, "ar-tafseer-al-saddi", "تيسير الكريم الرحمن في تفسير كلام المنان", "السعدي",
           "عبد الرحمن بن ناصر السعدي", 1376, attach_gaps_to_previous=True),
    Tafsir("baghawi", 27, "ar-tafsir-al-baghawi", "معالم التنزيل", "البغوي",
           "الحسين بن مسعود البغوي", 516),
    Tafsir("ibn-kathir", 22, "ar-tafsir-ibn-kathir", "تفسير القرآن العظيم", "ابن كثير",
           "إسماعيل بن عمر بن كثير", 774),
    Tafsir("qurtubi", 23, "ar-tafseer-al-qurtubi", "الجامع لأحكام القرآن", "القرطبي",
           "محمد بن أحمد القرطبي", 671),
    Tafsir("tabari", 37, "ar-tafsir-al-tabari", "جامع البيان عن تأويل آي القرآن", "الطبري",
           "محمد بن جرير الطبري", 310),
]

TAFSIR_BY_SLUG = {t.slug: t for t in TAFSIRS}
