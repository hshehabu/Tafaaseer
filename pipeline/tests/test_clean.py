import unittest

from tafaseer_pipeline.clean import ISNAD, NOTE, QURAN, REF, TEXT, clean_entry, html_to_text, normalize


def kinds(doc):
    return [p["k"] for p in doc["p"]]


class CleanTests(unittest.TestCase):
    def test_footnote_becomes_note_span(self):
        doc = clean_entry('قال: ما يرى [[في المطبوعة: "ما يرى"، والصواب من المخطوطة.]] ، بما أنعم')
        spans = doc["p"][0]["s"]
        self.assertIn([NOTE, 'في المطبوعة: "ما يرى"، والصواب من المخطوطة.'], spans)
        self.assertNotIn("[[", "".join(s[1] for s in spans))

    def test_quran_quotes_lose_their_delimiters(self):
        doc = clean_entry("وقوله: ﴿الْحَمْدُ لِلَّهِ﴾ الشكر لله. ثم قال: { ذَلِكَ الْكِتَابُ } أي هذا الكتاب")
        quran = [s[1] for s in doc["p"][0]["s"] if s[0] == QURAN]
        self.assertEqual(quran, ["الْحَمْدُ لِلَّهِ", "ذَلِكَ الْكِتَابُ"])

    def test_curly_braces_with_only_digits_are_not_quran(self):
        doc = clean_entry("{1} وأما الحروف المقطعة في أوائل السورة فالأسلم فيها السكوت.")
        self.assertFalse(any(s[0] == QURAN for s in doc["p"][0]["s"]))

    def test_sura_reference(self):
        doc = clean_entry("فإنه آخر آية نزلت [البقرة: ٢٨١] من السماء.")
        self.assertIn([REF, "[البقرة: ٢٨١]"], doc["p"][0]["s"])

    def test_isnad_span_and_word_counts(self):
        doc = clean_entry("حدثنا بشر، قال: ثنا يزيد، قال: ثنا سعيد، عن قتادة قوله: نزلت في كذا.")
        spans = doc["p"][0]["s"]
        self.assertEqual(spans[0][0], ISNAD)
        stats = doc["_stats"]
        self.assertLess(stats["words_without_isnad"], stats["words"])

    def test_paragraph_kinds(self):
        doc = clean_entry("القول في تأويل قوله: ﴿قل هو الله أحد﴾\n"
                          "تسمية السورة\n"
                          "لقد بسملت ليلى غداة لقيتها ... فيا حبذا ذاك الحبيب المبسمل\n"
                          "* * *\n"
                          "ثم ذكر منته عليهم بوعده لموسى أربعين ليلة لينزل عليهم التوراة المتضمنة للنعم.")
        self.assertEqual(kinds(doc), ["h", "h", "poem", "hr", "p"])

    def test_note_only_line_is_an_editor_paragraph(self):
        doc = clean_entry("[[هذه الآية لم يتكلم عليها المؤلف ولم تذكر في النسخ.]]")
        self.assertEqual(doc["p"], [{"k": "ed", "s": [[NOTE, "هذه الآية لم يتكلم عليها المؤلف ولم تذكر في النسخ."]]}])
        self.assertGreater(doc["_stats"]["words"], 0)

    def test_bracketed_label_becomes_heading(self):
        doc = clean_entry("[التفسير]\n﴿الٓمٓ﴾ هذه الحروف المقطعة في أوائل السور.")
        self.assertEqual(doc["p"][0], {"k": "h", "s": [[TEXT, "التفسير"]]})

    def test_tabari_asterism_and_trailing_dash(self):
        doc = clean_entry("⁕ حدثني يونس قال: نعم.\nوأما الخبر الذي:-")
        self.assertTrue(doc["p"][0]["s"][0][1].startswith("حدثني"))
        self.assertTrue(doc["p"][1]["s"][-1][1].endswith("الذي:"))

    def test_normalize_punctuation(self):
        self.assertEqual(normalize("صلى الله عليه وسلم, وصحة ما جاء به"), "صلى الله عليه وسلم، وصحة ما جاء به")
        self.assertEqual(normalize("في أوائل السورة ؛ فالأسلم"), "في أوائل السورة؛ فالأسلم")
        self.assertEqual(normalize("الرحمـــن الرحيم"), "الرحمن الرحيم")

    def test_folio_markers_are_removed(self):
        self.assertEqual(" ".join(normalize("ثنا أبو أحمد عيسى ٦/أبْنُ أحمد").split()), "ثنا أبو أحمد عيسى بْنُ أحمد")

    def test_hard_wrapped_html_keeps_paragraphs(self):
        doc = clean_entry("<h2>تسمية السورة</h2><p>سميت البقرة لأنها انفردت\nبذكر قصة البقرة.</p><p>ثم قال.</p>")
        self.assertEqual(kinds(doc), ["h", "p", "p"])
        self.assertEqual(doc["p"][1]["s"][0][1], "سميت البقرة لأنها انفردت بذكر قصة البقرة.")

    def test_html_is_stripped(self):
        self.assertEqual(html_to_text("<p>قال <b>ابن</b> عباس</p><p>ثم</p>").strip().split("\n")[0], "قال ابن عباس")
        self.assertEqual(html_to_text("A &amp; B"), "A & B")

    def test_plain_text_passes_through(self):
        doc = clean_entry("الله الذي لا يستحق الألوهية والعبودية إلا هو.")
        self.assertEqual(doc["p"], [{"k": "p", "s": [[TEXT, "الله الذي لا يستحق الألوهية والعبودية إلا هو."]]}])


if __name__ == "__main__":
    unittest.main()
