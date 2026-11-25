import unittest

from tafaseer_pipeline.isnad import find_isnads


def hidden(text: str) -> list[str]:
    return [text[s:e] for s, e in find_isnads(text)]


def visible(text: str) -> str:
    out, pos = [], 0
    for s, e in find_isnads(text):
        out.append(text[pos:s])
        pos = e
    out.append(text[pos:])
    return "".join(out)


class IsnadTests(unittest.TestCase):
    def test_tabari_chain_keeps_last_narrator(self):
        text = ("حدثنا أحمد بن منيع المَرْوَزِي ومحمود بن خداش الطالَقاني، قالا ثنا أبو سعيد الصنعاني، قال: "
                "ثنا أبو جعفر الرازي، عن الربيع بن أنس، عن أبي العالية، عن أبي بن كعب، قال: قال المشركون للنبيّ ﷺ")
        self.assertEqual(visible(text), "عن أبي بن كعب، قال: قال المشركون للنبيّ ﷺ")

    def test_diacritized_chain_after_attribution(self):
        text = ("قَالَ الْإِمَامُ أَحْمَدُ: حَدَّثَنَا عَبْدُ الرَّزَّاقِ حَدَّثَنَا سُفْيَانُ عَنْ سَعِيدٍ الْجَرِيرِيِّ "
                "عَنْ أَبِي السَّلِيلِ عَنْ عَبْدِ اللَّهِ بْنِ رَبَاحٍ، عَنْ أُبَيٍّ -هُوَ ابْنُ كَعْبٍ-أَنَّ النَّبِيَّ ﷺ سَأَلَهُ")
        self.assertTrue(visible(text).startswith("قَالَ الْإِمَامُ أَحْمَدُ: عَنْ أُبَيٍّ"))

    def test_abbreviation_thani(self):
        text = "حدثنا ابن حميد، قال: ثنا سلمة، قال: ثني ابن إسحاق، عن محمد، عن سعيد، قال: أتى رهط من اليهود"
        self.assertEqual(visible(text), "عن سعيد، قال: أتى رهط من اليهود")

    def test_baghawi_ana_abbreviation(self):
        text = ("أَخْبَرَنَا عَبْدُ الْوَاحِدِ بْنُ أَحْمَدَ الْمَلِيحِيُّ أَنَا أَحْمَدُ بْنُ عَبْدِ اللَّهِ النُّعَيْمِيُّ "
                "أَنَا مُحَمَّدُ بْنُ يُوسُفَ عَنْ يَحْيَى بْنِ يَعْمُرَ قَالَ: كَانَ أَوَّلُ مَنْ تَكَلَّمَ فِي الْقَدَرِ")
        self.assertTrue(visible(text).startswith("عَنْ يَحْيَى بْنِ يَعْمُرَ"))

    def test_keeps_companion_before_prophet(self):
        text = "حدثنا بشر، قال: ثنا يزيد، عن سعيد، عن أبي هريرة، عن النبي ﷺ قال: الدين النصيحة"
        self.assertEqual(visible(text), "عن أبي هريرة، عن النبي ﷺ قال: الدين النصيحة")

    def test_inna_is_not_an_abbreviation(self):
        text = "قالا له: أخبرنا -يا يوسف- بتفسير ما رأينا، إنا نراك من الذين يحسنون في عبادتهم لله"
        self.assertEqual(hidden(text), [])

    def test_imperative_without_names_is_not_a_chain(self):
        text = 'قُلْتُ: يَا رَسُولَ اللَّهِ، أَخْبِرْنِي عَنِ الْوُضُوءِ: فَقَالَ: "أَسْبِغِ الْوُضُوءَ"'
        self.assertEqual(hidden(text), [])

    def test_prophet_as_source_ends_the_chain(self):
        text = ("حَدَّثَنَا رَسُولُ اللَّهِ ﷺ حَدِيثَيْنَ قَدْ رَأَيْتُ أَحَدَهُمَا وَأَنَا أَنْتَظِرُ الْآخَرَ، "
                'حَدَّثَنَا "أَنَّ الْأَمَانَةَ نَزَلَتْ فِي جِذْرِ قُلُوبِ الرِّجَالِ"')
        self.assertEqual(hidden(text), [])

    def test_stops_at_matn_after_colon(self):
        text = "حدثنا ابن حميد، قال: ثنا جرير، عن منصور، قال: سألوه عن الصلاة وعن الصيام"
        self.assertEqual(visible(text), "عن منصور، قال: سألوه عن الصلاة وعن الصيام")

    def test_stops_at_anna(self):
        text = "حدثنا ابن بشار، قال: ثنا يحيى، عن عبيد الله، عن نافع أن ابن عمر كان يصلي عن يمينه"
        self.assertEqual(visible(text), "عن نافع أن ابن عمر كان يصلي عن يمينه")

    def test_never_crosses_quran_quote(self):
        text = "حدثنا بشر، قال: ثنا يزيد، ﴿عن الذين آمنوا﴾ عن قتادة"
        quote = (text.index("﴿"), text.index("﴾") + 1)
        for s, e in find_isnads(text, blocked=[quote]):
            self.assertLessEqual(e, quote[0])

    def test_single_link_is_not_hidden(self):
        self.assertEqual(hidden("حدثنا عمر بن الخطاب قال: بينا نحن عند رسول الله ﷺ"), [])


if __name__ == "__main__":
    unittest.main()
