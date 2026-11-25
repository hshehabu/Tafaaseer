import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from tafaseer_pipeline.loaders import (AyahIndex, attach_gaps_to_neighbours, load_mirror, load_qul_json,
                                       load_qul_sqlite)

# A tiny Quran: surah 1 has 3 ayahs, surah 2 has 4.
INDEX = AyahIndex([3, 4])


def ranges(entries):
    return sorted((e.ayah_ids[0], e.ayah_ids[-1], e.text) for e in entries)


class LoaderTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, name, data):
        path = self.dir / name
        path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
        return path

    def test_mirror_groups_consecutive_identical_text_within_a_surah(self):
        s1 = self.write("1.json", [{"surah": 1, "ayah": a, "text": t} for a, t in [(1, "أ"), (2, "ب"), (3, "ب")]])
        s2 = self.write("2.json", [{"surah": 2, "ayah": a, "text": t} for a, t in [(1, "ب"), (2, "×"), (4, "ج")]])
        entries = load_mirror({1: s1, 2: s2}, INDEX)
        # 2:1 repeats the text of 1:3 but starts a new surah; 2:2 is a placeholder; 2:3 is absent.
        self.assertEqual(ranges(entries), [(1, 1, "أ"), (2, 3, "ب"), (4, 4, "ب"), (7, 7, "ج")])

    def test_attach_gaps(self):
        s1 = self.write("1.json", [{"surah": 1, "ayah": a, "text": t} for a, t in [(2, "ب"), (3, "ج")]])
        s2 = self.write("2.json", [{"surah": 2, "ayah": a, "text": t} for a, t in [(1, "د"), (2, "×"), (4, "هـ")]])
        entries = load_mirror({1: s1, 2: s2}, INDEX)
        attached = attach_gaps_to_neighbours(entries, INDEX)
        self.assertEqual(attached, 3)  # 1:1 joins the next entry; 2:2 and 2:3 join 2:1
        self.assertEqual(ranges(entries), [(1, 2, "ب"), (3, 3, "ج"), (4, 6, "د"), (7, 7, "هـ")])

    def test_qul_json_pointers(self):
        path = self.write("t.json", {
            "1:1": {"text": "<b>أ</b>", "ayah_keys": ["1:1"]},
            "1:2": {"text": "ب", "ayah_keys": ["1:2", "1:3"]},
            "1:3": "1:2",
            "2:1": {"text": "ج", "ayah_keys": ["2:1"]},
            "2:2": "2:1",
            "2:3": "2:2",
        })
        entries = load_qul_json(path, INDEX)
        self.assertEqual(ranges(entries), [(1, 1, "<b>أ</b>"), (2, 3, "ب"), (4, 6, "ج")])

    def test_qul_sqlite_real_schema(self):
        # Column layout of QUL tafsir exports as read by hndrwn-dk/quran-offline-mobile:
        # tafsir(ayah_key, group_ayah_key, from_ayah, to_ayah, ayah_keys, text)
        path = self.dir / "qul.sqlite"
        con = sqlite3.connect(path)
        con.execute("CREATE TABLE tafsir (ayah_key TEXT, group_ayah_key TEXT, from_ayah TEXT, to_ayah TEXT, "
                    "ayah_keys TEXT, text TEXT)")
        con.executemany("INSERT INTO tafsir VALUES (?,?,?,?,?,?)", [
            ("2:1", "2:1", "2:1", "2:3", "2:1,2:2,2:3", "<p>أ</p>"),
            ("2:2", "2:1", "2:1", "2:3", "2:1,2:2,2:3", ""),
            ("2:3", "2:1", "2:1", "2:3", "2:1,2:2,2:3", ""),
            ("2:4", "2:4", "2:4", "2:4", "2:4", "<p>ب</p>"),
        ])
        con.commit()
        con.close()
        self.assertEqual(ranges(load_qul_sqlite(path, INDEX)), [(4, 6, "<p>أ</p>"), (7, 7, "<p>ب</p>")])

    def test_qul_sqlite_with_group_column(self):
        path = self.dir / "t.sqlite"
        con = sqlite3.connect(path)
        con.execute("CREATE TABLE tafsir (ayah_key TEXT, group_ayah_key TEXT, text TEXT)")
        con.executemany("INSERT INTO tafsir VALUES (?,?,?)", [
            ("1:1", "1:1", "أ"), ("1:2", "1:2", "ب"), ("1:3", "1:2", ""),
        ])
        con.commit()
        con.close()
        self.assertEqual(ranges(load_qul_sqlite(path, INDEX)), [(1, 1, "أ"), (2, 3, "ب")])


if __name__ == "__main__":
    unittest.main()
