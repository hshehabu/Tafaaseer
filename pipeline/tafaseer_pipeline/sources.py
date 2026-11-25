"""Download and cache the raw inputs."""

import json
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from . import config


def _download(url: str, dest: Path, retries: int = 3) -> Path:
    if dest.exists() and dest.stat().st_size > 0:
        return dest
    dest.parent.mkdir(parents=True, exist_ok=True)
    last_error: Exception | None = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": config.USER_AGENT})
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = resp.read()
            tmp = dest.with_suffix(dest.suffix + ".part")
            tmp.write_bytes(data)
            tmp.replace(dest)
            return dest
        except Exception as e:  # network errors, HTTP errors
            last_error = e
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"download failed after {retries} tries: {url}: {last_error}")


def quran_files() -> dict[str, Path]:
    base = config.CACHE_DIR / "quran"
    return {
        "text": _download(config.QURAN_TEXT_URL, base / "qpc_hafs.json"),
        "simple": _download(config.QURAN_SIMPLE_URL, base / "uthmani_simple.json"),
        "metadata": _download(config.TANZIL_METADATA_URL, base / "tanzil-quran-data.xml"),
    }


def mirror_files(tafsir: config.Tafsir, workers: int = 8) -> dict[int, Path]:
    base = config.CACHE_DIR / "mirror" / config.MIRROR_COMMIT[:12] / tafsir.mirror_slug
    jobs = {
        surah: (config.MIRROR_URL.format(slug=tafsir.mirror_slug, surah=surah), base / f"{surah}.json")
        for surah in range(1, config.TOTAL_SURAHS + 1)
    }
    missing = [s for s, (_, dest) in jobs.items() if not dest.exists()]
    if missing:
        print(f"  downloading {len(missing)} surah files for {tafsir.slug} ...", file=sys.stderr)
    with ThreadPoolExecutor(max_workers=workers) as pool:
        results = pool.map(lambda item: (item[0], _download(*item[1])), jobs.items())
        files = dict(results)
    for surah, path in files.items():  # fail early on a truncated or HTML error body
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            path.unlink(missing_ok=True)
            raise RuntimeError(f"{tafsir.slug} surah {surah}: downloaded file is not valid JSON; run again")
    return files


def qul_file(tafsir: config.Tafsir) -> Path | None:
    """A QUL export the user downloaded by hand into input/qul/<slug>.(json|sqlite|db)."""
    for ext in (".json", ".sqlite", ".db"):
        path = config.QUL_INPUT_DIR / f"{tafsir.slug}{ext}"
        if path.exists():
            return path
    return None
