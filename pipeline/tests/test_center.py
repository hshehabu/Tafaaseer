import sqlite3
import tempfile
import unittest
from pathlib import Path

from tafaseer_pipeline.center import load, prepare
from tafaseer_pipeline.config import CenterTable
from tafaseer_pipeline.loaders import AyahIndex


class PrepareTests(unittest.TestCase):
    def test_footnotes_become_qul_style_notes(self):
        self.assertEqual(prepare("الذي ينمي ¬في (ب): «ينمى».¥، وأما"), "الذي ينمي [[في (ب): «ينمى».]]، وأما")

    def test_leading_quoted_ayah_is_dropped(self):
        raw = "{وَمَا هَذِهِ الْحَيَاةُ الدُّنْيَا (64) فَإِذَا رَكِبُوا (65)}.\r\nقَوْلُهُ تَعَالَى: {وَمَا هَذِهِ} اللَّهْوُ"
        self.assertEqual(prepare(raw), "قَوْلُهُ تَعَالَى: {وَمَا هَذِهِ} اللَّهْوُ")

    def test_a_quote_later_in_the_text_is_kept(self):
        raw = "يقول تعالى: {لِإِيلَافِ قُرَيْشٍ (1) إِيلَافِهِمْ (2)} الآية"
        self.assertEqual(prepare(raw), "يقول تعالى: {لِإِيلَافِ قُرَيْشٍ (١) إِيلَافِهِمْ (٢)} الآية")

    def test_saadi_ayah_number_markers(self):
        raw = "{فَإِذَا رَكِبُوا (65)}.\n{65} ثم ألزم تعالى {66 - 67} وقوله"
        self.assertEqual(prepare(raw), "ثم ألزم تعالى (٦٦ - ٦٧) وقوله")

    def test_spaced_parentheses_are_quotes_only_without_braces(self):
        self.assertEqual(prepare("فأنزل الله: ( قُلْ هُوَ اللَّهُ أَحَدٌ ) . حدثنا"), "فأنزل الله: {قُلْ هُوَ اللَّهُ أَحَدٌ} . حدثنا")
        self.assertEqual(prepare("{قُلْ} قال ( كذا وكذا )"), "{قُلْ} قال ( كذا وكذا )")


class LoadTests(unittest.TestCase):
    def test_one_entry_per_ayah_and_repeats_share_one(self):
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "center.db"
            con = sqlite3.connect(db)
            con.execute("CREATE TABLE t (sura INTEGER, aya INTEGER, tafsir TEXT)")
            con.executemany("INSERT INTO t VALUES (?,?,?)",
                            [(1, 1, "أ"), (1, 2, "ب"), (1, 3, "ب"), (2, 1, "ب"), (2, 2, "{كَذَا (2)}")])
            con.commit()
            con.close()
            entries = load(db, CenterTable("t"), AyahIndex([3, 2]))
        # 1:2-3 repeat, so they share; 2:1 has the same text but starts a new surah;
        # 2:2 is only its own quote, so it joins the entry before it.
        self.assertEqual([(e.ayah_ids, e.text) for e in entries], [([1], "أ"), ([2, 3], "ب"), ([4, 5], "ب")])
